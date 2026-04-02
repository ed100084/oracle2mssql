"""LLM-based PL/SQL to T-SQL converter using Claude API.

POC 目標：處理 EHRPHRA3_PKG，將每個 Procedure/Function 個別轉換並存檔。

架構：
  1. 拆解 Package Body → 個別 Procedure/Function block
  2. 對每個 block 呼叫 Claude API 轉換成 T-SQL
  3. 用 deployer.syntax_check() 做 dry-run 驗證
  4. 失敗時把錯誤回饋給 Claude 做第二輪修正
  5. 所有結果存檔到 output/llm_converted/<schema>/

使用方式：
  python -m ora2mssql.llm_converter            # 轉換 EHRPHRA3_PKG（預設）
  python -m ora2mssql.llm_converter --package EHRPHRA3_PKG

環境變數：
  ANTHROPIC_API_KEY  (必要，若未設定則跳過實際 API 呼叫，輸出 placeholder)
"""
from __future__ import annotations

import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

logger = logging.getLogger("ora2mssql.llm")

# ─────────────────────────────────────────────────────────────────────────────
# 資料結構
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class ProcedureBlock:
    """代表從 Package Body 中拆出的單一 Procedure 或 Function。"""
    name: str
    kind: str          # "PROCEDURE" or "FUNCTION"
    source: str        # 原始 PL/SQL 片段（含 PROCEDURE/FUNCTION 關鍵字到 END name;）
    package_name: str  # 所屬 Package 名稱（例如 EHRPHRA3_PKG）
    order_index: int   # 在 Package 中的順序


@dataclass
class LLMConversionResult:
    """單一 SP/Function 的轉換結果。"""
    block: ProcedureBlock
    tsql: str                        # 最終輸出的 T-SQL
    attempts: int = 1                # 轉換嘗試次數（含重試）
    syntax_ok: bool = False          # 最後一次 dry-run 是否通過
    syntax_error: Optional[str] = None  # 最後一次 dry-run 錯誤訊息（None = 通過）
    output_path: Optional[Path] = None  # 寫出的 .sql 檔案路徑
    skipped_api: bool = False        # True = 沒有 API key，輸出 placeholder


# ─────────────────────────────────────────────────────────────────────────────
# 1. 拆解 Package Body
# ─────────────────────────────────────────────────────────────────────────────

def split_package_body(source: str, package_name: str) -> list[ProcedureBlock]:
    """將 Package Body 原始碼拆成個別的 Procedure/Function block。

    策略：
      - 找所有頂層 PROCEDURE / FUNCTION 定義（縮排為 0 或只有空白的行首）
      - 每個 block 結束點 = 下一個同層級 PROCEDURE/FUNCTION 開始前，
        或找到「END <name>;」行
    """
    blocks: list[ProcedureBlock] = []

    # 移除 PACKAGE BODY <name> IS / AS 標頭，只保留內容
    # 也移除最末的 END <pkg_name>; / END;
    body = _strip_package_wrapper(source)

    # 找所有頂層 PROCEDURE / FUNCTION 定義起始位置
    # 頂層定義：行首（可含空白）接 PROCEDURE 或 FUNCTION
    header_pattern = re.compile(
        r'^[ \t]*(PROCEDURE|FUNCTION)\s+(\w+)',
        re.IGNORECASE | re.MULTILINE
    )

    matches = list(header_pattern.finditer(body))

    for i, m in enumerate(matches):
        kind = m.group(1).upper()
        name = m.group(2)
        start = m.start()

        # 結束位置：下一個頂層定義的起始 - 1，或字串結尾
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)

        raw_block = body[start:end].rstrip()

        # 修剪：有時兩個定義間有大量空白，只取到最後的 END <name>; 或 END;
        raw_block = _trim_block_end(raw_block, name)

        blocks.append(ProcedureBlock(
            name=name,
            kind=kind,
            source=raw_block,
            package_name=package_name,
            order_index=i,
        ))
        logger.debug(f"  拆解 {kind} {name}（{len(raw_block)} 字元）")

    logger.info(f"共拆解 {len(blocks)} 個 Procedure/Function 自 {package_name}")
    return blocks


def _strip_package_wrapper(source: str) -> str:
    """移除 PACKAGE BODY <name> IS/AS ... 外層包裝，取出主體內容。"""
    # 移除第一行的 PACKAGE BODY <name> IS/AS
    body = re.sub(
        r'^\s*PACKAGE\s+BODY\s+\w+\s+(IS|AS)\s*',
        '',
        source,
        flags=re.IGNORECASE | re.DOTALL,
        count=1,
    )
    # 移除最末的 END <pkg_name>; 或 END;（單獨一行）
    body = re.sub(
        r'\n\s*END\s+\w*\s*;\s*$',
        '',
        body,
        flags=re.IGNORECASE,
    )
    return body.strip()


def _trim_block_end(block: str, proc_name: str) -> str:
    """嘗試在 block 內找到 END <name>; 或 END; 做精確收尾。

    如果找不到，回傳原本的 block（保守策略）。
    """
    # 尋找「END <name>;」（允許空白）
    pattern = re.compile(
        r'\bEND\s+' + re.escape(proc_name) + r'\s*;',
        re.IGNORECASE
    )
    m = pattern.search(block)
    if m:
        return block[:m.end()].rstrip()

    # 退而求其次：找最後一個「END;」
    last_end = None
    for m2 in re.finditer(r'\bEND\s*;', block, re.IGNORECASE):
        last_end = m2
    if last_end:
        return block[:last_end.end()].rstrip()

    return block


# ─────────────────────────────────────────────────────────────────────────────
# 2. 建立 Claude Prompt
# ─────────────────────────────────────────────────────────────────────────────

_SYSTEM_PROMPT = """\
你是一位資深的資料庫轉換專家，專精於 Oracle PL/SQL 轉換到 Microsoft SQL Server T-SQL。
請嚴格依照使用者的指示進行轉換，只輸出 T-SQL 程式碼，不要加任何說明文字或 markdown 區塊標記。
"""

_CONVERSION_RULES = """\
## 轉換規則

### 目標環境
- 目標資料庫：Microsoft SQL Server 2022
- Package 名稱作為 Schema 前綴，例如 EHRPHRA3_PKG → [ehrphra3_pkg].[<proc_name>]
- 所有 Stored Procedure 使用 CREATE OR ALTER PROCEDURE

### 語法對應
| Oracle PL/SQL | T-SQL |
|---|---|
| PROCEDURE xxx AS / IS | CREATE OR ALTER PROCEDURE [schema].[xxx] AS |
| FUNCTION xxx RETURN type | CREATE OR ALTER FUNCTION [schema].[xxx](...) RETURNS type |
| 參數（無 @） | 參數加 @ 前綴，OUT/IN OUT 參數加 OUTPUT 關鍵字 |
| v_var VARCHAR2(n) | DECLARE @v_var NVARCHAR(n) |
| NVL(a, b) | ISNULL(a, b) |
| NVL2(a, b, c) | IIF(a IS NOT NULL, b, c) |
| DECODE(x, v1, r1, ..., def) | CASE x WHEN v1 THEN r1 ... ELSE def END |
| TO_CHAR(date, fmt) | FORMAT(date, fmt) 或 ora_compat.TO_CHAR_DATE(date, fmt) |
| TO_DATE(str, fmt) | ora_compat.TO_DATE(str, fmt) |
| TO_NUMBER(str) | TRY_CAST(str AS DECIMAL(38,10)) |
| SYSDATE | GETDATE() |
| TRUNC(date) | CAST(date AS DATE) |
| TRUNC(num, n) | ROUND(num, n, 1) |
| LAST_DAY(date) | EOMONTH(date) |
| ADD_MONTHS(date, n) | DATEADD(MONTH, n, date) |
| MONTHS_BETWEEN(d1,d2) | ora_compat.MONTHS_BETWEEN(d1, d2) |
| INSTR(str, sub) | CHARINDEX(sub, str) |
| SUBSTR(str, s, l) | SUBSTRING(str, s, l) |
| LENGTH(str) | LEN(str) |
| UPPER/LOWER/TRIM | 同名（T-SQL 支援） |
| LPAD(str, n, p) | RIGHT(REPLICATE(p,n) + str, n) |
| RPAD(str, n, p) | LEFT(str + REPLICATE(p,n), n) |
| <seq>.NEXTVAL | NEXT VALUE FOR <schema>.<seq> |
| COMMIT WORK / COMMIT | COMMIT TRANSACTION 或 直接省略（若 autocommit） |
| SAVEPOINT sp | SAVE TRANSACTION sp |
| ROLLBACK TO sp | ROLLBACK TRANSACTION sp |
| SELECT ... FROM DUAL | SELECT ... （去掉 FROM DUAL） |
| EXCEPTION WHEN NO_DATA_FOUND | BEGIN TRY ... END TRY BEGIN CATCH ... END CATCH |
| EXCEPTION WHEN OTHERS | CATCH 中用 ERROR_MESSAGE(), ERROR_NUMBER() |
| SQLERRM | ERROR_MESSAGE() |
| SQLCODE | ERROR_NUMBER() |
| RAISE_APPLICATION_ERROR | THROW 或 RAISERROR |
| DBMS_OUTPUT.PUT_LINE | PRINT |
| GOTO label | GOTO label（T-SQL 支援） |
| EXIT WHEN cond | IF cond BREAK |
| cursor%ROWTYPE | 展開成個別欄位變數（加 -- [MANUAL_REVIEW] 提示） |
| FOR rec IN cursor LOOP | 改用 DECLARE cursor / OPEN / FETCH / CLOSE |
| FORALL / BULK COLLECT | 加 -- [MANUAL_REVIEW] 提示，改用逐行 INSERT |

### 特別注意
1. T-SQL 變數宣告必須在 BEGIN 內（不是 AS 和 BEGIN 之間）
2. IF / ELSIF → IF / ELSE IF，每個 IF 區塊需要 BEGIN...END
3. LOOP...EXIT WHEN → WHILE (1=1) BEGIN ... IF cond BREAK END
4. FOR i IN 1..n LOOP → WHILE @i <= @n BEGIN ... SET @i = @i + 1 END
5. 字串連接：|| → +，NULL 串接需注意加 ISNULL
6. 型別：VARCHAR2→NVARCHAR, NUMBER→DECIMAL(38,10), DATE→DATETIME2, INTEGER→INT
7. Package 內的私有函式呼叫需加 Schema 前綴，例如 f_hra4010_B → [ehrphra3_pkg].f_hra4010_B
8. 輸出結果只有 T-SQL，不含 markdown 程式碼區塊標記（不要 ```sql）
"""


def build_conversion_prompt(block: ProcedureBlock, target_schema: str) -> str:
    """建立給 Claude 的轉換 prompt（user 訊息部分）。"""
    return f"""{_CONVERSION_RULES}

## 轉換任務

請將以下 Oracle PL/SQL {block.kind} 轉換成 MSSQL 2022 T-SQL。

- Package 名稱：{block.package_name}
- 目標 Schema：[{target_schema}]
- 物件名稱：{block.name}

### 原始 Oracle PL/SQL：

{block.source}

請輸出完整的 T-SQL CREATE OR ALTER PROCEDURE / FUNCTION，結尾加上 GO。
"""


def build_fix_prompt(block: ProcedureBlock, tsql: str, error_message: str, target_schema: str) -> str:
    """建立修正 prompt（附上錯誤訊息要求 Claude 修正）。"""
    return f"""{_CONVERSION_RULES}

## 修正任務

以下 T-SQL 在 MSSQL 語法檢查時出現錯誤，請修正並輸出完整的 T-SQL。

- Schema：[{target_schema}]
- 物件名稱：{block.name}

### 有錯誤的 T-SQL：

{tsql}

### MSSQL 錯誤訊息：

{error_message}

請修正上述錯誤並輸出完整的 T-SQL CREATE OR ALTER PROCEDURE / FUNCTION，結尾加上 GO。
"""


# ─────────────────────────────────────────────────────────────────────────────
# 3. Claude API 呼叫
# ─────────────────────────────────────────────────────────────────────────────

def call_claude_api(user_prompt: str, model: str = "claude-sonnet-4-6") -> str:
    """呼叫 Anthropic Claude API 進行轉換。

    若環境變數 ANTHROPIC_API_KEY 未設定，回傳 placeholder 字串。
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY", "")
    if not api_key:
        # ── PLACEHOLDER ──────────────────────────────────────────────────────
        # 設定 ANTHROPIC_API_KEY 環境變數後，此處會進行實際 API 呼叫。
        # 目前回傳 placeholder，供框架驗證流程用。
        # ─────────────────────────────────────────────────────────────────────
        logger.warning("ANTHROPIC_API_KEY 未設定，回傳 placeholder T-SQL")
        return _placeholder_tsql()

    try:
        import anthropic  # pip install anthropic
    except ImportError:
        logger.error("anthropic 套件未安裝，請執行: pip install anthropic")
        return _placeholder_tsql()

    client = anthropic.Anthropic(api_key=api_key)

    message = client.messages.create(
        model=model,
        max_tokens=8192,
        system=_SYSTEM_PROMPT,
        messages=[
            {"role": "user", "content": user_prompt}
        ],
    )

    # 取出文字內容
    content = message.content[0].text if message.content else ""

    # 清除意外混入的 markdown 程式碼區塊標記
    content = re.sub(r'^```(?:sql|tsql)?\s*\n?', '', content.strip(), flags=re.IGNORECASE)
    content = re.sub(r'\n?```\s*$', '', content.strip())

    return content.strip()


def _placeholder_tsql() -> str:
    """當無法呼叫 API 時回傳的 placeholder T-SQL。"""
    return """\
-- [LLM_PLACEHOLDER] 此檔案為框架驗證用 placeholder
-- 設定環境變數 ANTHROPIC_API_KEY 後重新執行以取得真實轉換結果
--
-- 範例：
--   export ANTHROPIC_API_KEY=sk-ant-...
--   python -m ora2mssql.llm_converter
--
CREATE OR ALTER PROCEDURE [placeholder].[placeholder_proc]
AS
BEGIN
    PRINT 'placeholder - 請設定 ANTHROPIC_API_KEY';
END
GO
"""


# ─────────────────────────────────────────────────────────────────────────────
# 4. Dry-run 語法驗證（複用 deployer.syntax_check）
# ─────────────────────────────────────────────────────────────────────────────

def run_syntax_check(sql: str, config) -> tuple[bool, str]:
    """對單一 T-SQL 字串做 MSSQL SET PARSEONLY 語法檢查。

    回傳 (ok: bool, error_message: str)
    """
    try:
        from .deployer import get_mssql_connection, syntax_check
        conn = get_mssql_connection(config)
        try:
            ok, err = syntax_check(conn, sql)
        finally:
            conn.close()
        return ok, err
    except Exception as e:
        return False, f"連線失敗：{e}"


# ─────────────────────────────────────────────────────────────────────────────
# 5. 主轉換流程
# ─────────────────────────────────────────────────────────────────────────────

def convert_package_with_llm(
    package_name: str,
    config,
    max_retries: int = 1,
    model: str = "claude-sonnet-4-6",
    skip_syntax_check: bool = False,
) -> list[LLMConversionResult]:
    """對指定 Package 進行 LLM-based 轉換的完整流程。

    Args:
        package_name: Oracle Package 名稱，例如 "EHRPHRA3_PKG"
        config:       AppConfig 實例（含 mssql/conversion 設定）
        max_retries:  語法檢查失敗後的最大重試次數（預設 1 次）
        model:        使用的 Claude 模型
        skip_syntax_check: True 時跳過 MSSQL 連線驗證（純輸出模式）

    Returns:
        每個 Procedure/Function 的 LLMConversionResult 清單
    """
    from .utils import sanitize_name, ensure_dir, write_file, read_file

    output_dir = Path(config.conversion.output_dir)
    extracted_dir = output_dir / "extracted"

    # ── 讀取 Package Body 原始碼 ──────────────────────────────────────────
    # 嘗試從 extracted 目錄讀取（由 extractor 產出）
    source_owner = _find_package_owner(package_name, config)
    body_path = extracted_dir / source_owner / "PACKAGE_BODY" / f"{package_name}.sql"

    if not body_path.exists():
        # 退而求其次：從 PACKAGE/ 目錄讀原始 .sql
        body_path = Path("PACKAGE") / f"{package_name}.sql"

    if not body_path.exists():
        raise FileNotFoundError(f"找不到 {package_name} 的 Package Body：{body_path}")

    logger.info(f"讀取 Package Body：{body_path}")
    source = body_path.read_text(encoding="utf-8", errors="replace")

    # ── 拆解成個別 Procedure/Function ─────────────────────────────────────
    blocks = split_package_body(source, package_name)
    if not blocks:
        logger.warning(f"未從 {package_name} 拆解出任何 Procedure/Function")
        return []

    # ── 決定 target schema ────────────────────────────────────────────────
    target_schema = config.conversion.schema_mapping.get(
        package_name, sanitize_name(package_name)
    )

    # ── 建立輸出目錄 ──────────────────────────────────────────────────────
    llm_out_dir = ensure_dir(output_dir / "llm_converted" / target_schema)

    results: list[LLMConversionResult] = []
    api_key_present = bool(os.environ.get("ANTHROPIC_API_KEY", ""))

    for block in blocks:
        logger.info(f"[{block.order_index+1}/{len(blocks)}] 轉換 {block.kind} {block.name}")

        result = LLMConversionResult(block=block, tsql="")
        result.skipped_api = not api_key_present

        # ── 第一輪：呼叫 Claude API ────────────────────────────────────────
        prompt = build_conversion_prompt(block, target_schema)
        tsql = call_claude_api(prompt, model=model)
        result.tsql = tsql
        result.attempts = 1

        # ── Dry-run 驗證 ──────────────────────────────────────────────────
        if skip_syntax_check or not api_key_present:
            # 無 API key 時略過 syntax check，直接輸出 placeholder
            result.syntax_ok = False
            result.syntax_error = "跳過（無 API key 或 skip_syntax_check=True）"
        else:
            ok, err = run_syntax_check(tsql, config)
            result.syntax_ok = ok
            result.syntax_error = err if not ok else None

            # ── 重試（最多 max_retries 次）────────────────────────────────
            for attempt in range(max_retries):
                if result.syntax_ok:
                    break
                logger.warning(
                    f"  語法錯誤（第 {attempt+1}/{max_retries} 次修正）：{err[:120]}"
                )
                fix_prompt = build_fix_prompt(block, tsql, err, target_schema)
                tsql = call_claude_api(fix_prompt, model=model)
                result.tsql = tsql
                result.attempts += 1

                ok, err = run_syntax_check(tsql, config)
                result.syntax_ok = ok
                result.syntax_error = err if not ok else None

        # ── 寫出 .sql 檔案 ────────────────────────────────────────────────
        out_filename = f"{block.name}.sql"
        out_path = llm_out_dir / out_filename
        write_file(out_path, _build_output_sql(result, target_schema))
        result.output_path = out_path

        status = "✓ PASS" if result.syntax_ok else ("⚠ PLACEHOLDER" if result.skipped_api else "✗ FAIL")
        logger.info(f"  {status} → {out_path}")

        results.append(result)

    # ── 儲存轉換摘要 JSON ─────────────────────────────────────────────────
    summary_path = llm_out_dir / "_conversion_summary.json"
    _save_summary(results, summary_path, package_name, target_schema)
    logger.info(f"摘要已存：{summary_path}")

    return results


def _find_package_owner(package_name: str, config) -> str:
    """從 config.source_schemas 找 Package 所屬 owner（預設第一個）。"""
    schemas = config.conversion.source_schemas
    return schemas[0] if schemas else "HRP"


def _build_output_sql(result: LLMConversionResult, target_schema: str) -> str:
    """在轉換結果前加上標頭註解。"""
    lines = [
        f"-- ============================================================",
        f"-- Package  : {result.block.package_name}",
        f"-- Object   : {result.block.name} ({result.block.kind})",
        f"-- Schema   : [{target_schema}]",
        f"-- Attempts : {result.attempts}",
        f"-- SyntaxOK : {result.syntax_ok}",
    ]
    if result.syntax_error:
        lines.append(f"-- Error    : {result.syntax_error[:200]}")
    if result.skipped_api:
        lines.append("-- Note     : ANTHROPIC_API_KEY 未設定，輸出為 placeholder")
    lines.append("-- ============================================================")
    lines.append("")
    lines.append(result.tsql)
    return "\n".join(lines)


def _save_summary(
    results: list[LLMConversionResult],
    path: Path,
    package_name: str,
    target_schema: str,
) -> None:
    """將轉換摘要寫成 JSON 供人工 review。"""
    from .utils import write_file

    summary = {
        "package": package_name,
        "target_schema": target_schema,
        "total": len(results),
        "syntax_ok": sum(1 for r in results if r.syntax_ok),
        "syntax_failed": sum(1 for r in results if not r.syntax_ok and not r.skipped_api),
        "skipped_api": sum(1 for r in results if r.skipped_api),
        "objects": [
            {
                "name": r.block.name,
                "kind": r.block.kind,
                "attempts": r.attempts,
                "syntax_ok": r.syntax_ok,
                "syntax_error": r.syntax_error,
                "output_path": str(r.output_path) if r.output_path else None,
                "skipped_api": r.skipped_api,
            }
            for r in results
        ],
    }
    write_file(path, json.dumps(summary, indent=2, ensure_ascii=False))


# ─────────────────────────────────────────────────────────────────────────────
# 6. CLI 入口
# ─────────────────────────────────────────────────────────────────────────────

def main(argv: list[str] | None = None) -> None:
    """CLI 入口：python -m ora2mssql.llm_converter [--package PKG] [--skip-check] [--model MODEL]"""
    import argparse
    from .utils import setup_logging
    from .config import load_config

    parser = argparse.ArgumentParser(
        description="LLM-based Oracle PL/SQL → T-SQL 轉換器（POC）"
    )
    parser.add_argument(
        "--package", "-p",
        default="EHRPHRA3_PKG",
        help="要轉換的 Oracle Package 名稱（預設：EHRPHRA3_PKG）",
    )
    parser.add_argument(
        "--config", "-c",
        default="config.yaml",
        help="設定檔路徑（預設：config.yaml）",
    )
    parser.add_argument(
        "--model",
        default="claude-sonnet-4-6",
        help="Claude 模型（預設：claude-sonnet-4-6）",
    )
    parser.add_argument(
        "--max-retries",
        type=int,
        default=1,
        help="語法錯誤後最多重試次數（預設：1）",
    )
    parser.add_argument(
        "--skip-check",
        action="store_true",
        help="跳過 MSSQL 語法檢查（純輸出模式，無需資料庫連線）",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="顯示 DEBUG 層級日誌",
    )

    args = parser.parse_args(argv)
    setup_logging(verbose=args.verbose)

    logger.info("=" * 60)
    logger.info(f"LLM Converter POC — 目標 Package：{args.package}")
    logger.info(f"模型：{args.model}，最大重試：{args.max_retries}")
    if not os.environ.get("ANTHROPIC_API_KEY"):
        logger.warning("⚠ ANTHROPIC_API_KEY 未設定 — 將輸出 placeholder，跳過實際 API 呼叫")
    logger.info("=" * 60)

    config = load_config(args.config)

    results = convert_package_with_llm(
        package_name=args.package,
        config=config,
        max_retries=args.max_retries,
        model=args.model,
        skip_syntax_check=args.skip_check,
    )

    # ── 終端摘要 ──────────────────────────────────────────────────────────
    total = len(results)
    passed = sum(1 for r in results if r.syntax_ok)
    failed = sum(1 for r in results if not r.syntax_ok and not r.skipped_api)
    skipped = sum(1 for r in results if r.skipped_api)

    print("\n" + "=" * 60)
    print(f"LLM 轉換完成：{args.package}")
    print(f"  總計：{total}  通過：{passed}  失敗：{failed}  Placeholder：{skipped}")
    if results:
        out_dir = results[0].output_path.parent if results[0].output_path else "?"
        print(f"  輸出目錄：{out_dir}")
    print("=" * 60)

    # 列出失敗項目供 review
    for r in results:
        if not r.syntax_ok and not r.skipped_api:
            print(f"  ✗ {r.block.name}: {r.syntax_error}")


if __name__ == "__main__":
    main()
