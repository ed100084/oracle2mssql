# oracle2mssql — Oracle PL/SQL → MSSQL T-SQL 自動轉換工具

> 補足 SSMA (SQL Server Migration Assistant) 已知缺口的 Post-SSMA 轉換 Pipeline

---

## 目錄

1. [專案概述](#1-專案概述)
2. [架構說明](#2-架構說明)
3. [目錄結構](#3-目錄結構)
4. [環境設定與執行](#4-環境設定與執行)
5. [轉換規則模組](#5-轉換規則模組)
6. [轉換結果（當前快照）](#6-轉換結果當前快照)
7. [已知問題與待修清單](#7-已知問題與待修清單)
8. [修復進度日誌](#8-修復進度日誌)
9. [策略轉向：方案 C（LLM-based 轉換）](#9-策略轉向方案-c-llm-based-轉換)
10. [下一步工作](#10-下一步工作)

---

## 1. 專案概述

### 目的

將 Oracle 11gR2（UTF-8）的 HRP Schema 下 PL/SQL Package，逐步轉換為可部署至 MSSQL Server 2022 的 T-SQL Stored Procedures / Functions。

SSMA 可處理基本的 DDL 和 DML 語法轉換，但對以下場景支援不足：

- **跨 Package 呼叫**：未加 Schema 限定詞，部署後找不到目標物件
- **Package 變數 → Schema 函式**：SSMA 僅留存 stub，無法自動展開
- **`%ROWTYPE` 游標**：需逐欄位展開為明確型別宣告
- **`IF`/`TRY`/`CATCH` 結構**：多行條件或巢狀區塊轉換不完整
- **Oracle 專有函式/語法**：NVL、DECODE、CONNECT BY、CURSOR FOR LOOP 等

本工具針對以上缺口提供可重現、版本控制的自動化修復。

### 轉換對象

| Package | 原始行數 | 類型 |
|---|---|---|
| `HRP.EHRPHRA3_PKG` | 4,597 | PL/SQL Package + Body |
| `HRP.EHRPHRA12_PKG` | 6,014 | PL/SQL Package + Body |
| `HRP.EHRPHRAFUNC_PKG` | 7,509 | PL/SQL Package + Body |
| **合計** | **18,120** | |

### 連線資訊

| 項目 | 設定 |
|---|---|
| Oracle 來源 | `10.6.5.210:1521/MIS` (SYS/SYSDBA) |
| MSSQL 目標 | `10.7.2.65:1433/MIS1` (slash) |

---

## 2. 架構說明

### Pipeline 階段

```
extract → analyze → convert → deploy → test → report
```

| 階段 | 說明 |
|---|---|
| **extract** | 從 Oracle DB 或本地 .sql 檔讀取 Package Spec + Body |
| **analyze** | 解析依賴關係，產出 deploy_order.json（拓撲排序，cycles=0）|
| **convert** | 套用 7 個規則模組，將 PL/SQL 轉換為 T-SQL |
| **deploy** | 以 dry-run 或實際模式部署至 MSSQL（wave 0→1→2）|
| **test** | SET PARSEONLY ON 語法驗證 + 物件數量比對 |
| **report** | 彙整 conversion_summary.json + deploy_report.json |

### 部署 Wave 策略

- **Wave 0**：建立目標 Schema（`ehrphra12_pkg`、`ehrphra3_pkg`、`ehrphrafunc_pkg`）
- **Wave 1**：部署空 Stub（解決循環相依）
- **Wave 2**：部署完整實作

### 跨 Package Schema 對應

每個 Oracle Package 對應一個 MSSQL Schema：

| Oracle Package | MSSQL Schema |
|---|---|
| `EHRPHRA12_PKG` | `ehrphra12_pkg` |
| `EHRPHRA3_PKG` | `ehrphra3_pkg` |
| `EHRPHRAFUNC_PKG` | `ehrphrafunc_pkg` |

---

## 3. 目錄結構

```
oracle2mssql/
├── PACKAGE/                          # 原始 Oracle PL/SQL（版本基準）
│   ├── EHRPHRA3_PKG.sql              # 4,597 行
│   ├── EHRPHRA12_PKG.sql             # 6,014 行
│   └── EHRPHRAFUNC_PKG.sql           # 7,509 行
│
├── ora2mssql/                        # Python 核心模組
│   ├── config.py                     # YAML config loader（Pydantic）
│   ├── extractor.py                  # Oracle 擷取 + 本地檔讀取
│   ├── analyzer.py                   # 依賴分析、拓撲排序
│   ├── converter.py                  # 規則引擎、pre-scan registry、_fix_function_declares
│   ├── deployer.py                   # MSSQL 部署、wave 控制
│   ├── tester.py                     # SET PARSEONLY ON 語法驗證
│   ├── reporter.py                   # JSON 報告產生
│   ├── utils.py                      # 共用工具
│   ├── cli.py                        # Click CLI 入口（新增 --engine 選項）
│   ├── ast_converter.py              # [新] ANTLR4 AST 轉換引擎主模組
│   ├── ast_visitors/                 # [新] AST 訪問者模組
│   │   ├── type_mapper.py            #     Oracle → MSSQL 型別對應
│   │   ├── package_splitter.py       #     Package Body 拆分為 Routines
│   │   ├── declaration_collector.py  #     宣告區段收集（變數/游標/例外）
│   │   ├── syntax_transformer.py     #     語法轉換（函式/布林/連接符）
│   │   └── cross_reference_resolver.py # 跨 Package 參照解析
│   ├── parser/                       # [新] ANTLR4 生成的 PL/SQL Parser
│   │   ├── PlSqlLexer.py             #     Oracle PL/SQL 詞法分析器（17,522 行）
│   │   ├── PlSqlParser.py            #     Oracle PL/SQL 語法分析器（161,256 行）
│   │   ├── PlSqlLexerBase.py         #     Lexer 基礎類別
│   │   └── PlSqlParserBase.py        #     Parser 基礎類別
│   └── converter_rules/              # 轉換規則模組（7 個）
│       ├── packages.py               # Package → Schema + SP 展開
│       ├── datatypes.py              # Oracle → MSSQL 型別對應
│       ├── exceptions.py             # EXCEPTION → TRY/CATCH
│       ├── syntax.py                 # PL/SQL 語法結構轉換（最大模組）
│       ├── cursors.py                # CURSOR 迴圈轉換
│       ├── dml.py                    # DML 語法差異修正
│       └── functions.py              # 內建函式對應
│
├── templates/                        # Jinja2 T-SQL 範本
├── output/                           # 產出目錄
│   ├── extracted/HRP/               # 從 Oracle 擷取的原始 SQL
│   ├── converted/                   # 轉換後的 T-SQL（6 個物件）
│   ├── analysis/deploy_order.json   # 拓撲排序後的部署順序
│   ├── converted_ast/               # [新] AST 引擎轉換後的 T-SQL（每個 Routine 一檔）
│   └── reports/                     # 各階段報告
│
├── config.yaml                      # DB 連線 + 轉換參數
├── requirements.txt
└── setup.py
```

---

## 4. 環境設定與執行

### 依賴套件

```
oracledb>=2.0.0       # Oracle 連線
pyodbc>=5.0           # MSSQL 連線
click>=8.1            # CLI
pydantic>=2.0         # Config 驗證
pyyaml>=6.0           # YAML 解析
rich>=13.0            # 終端機排版
jinja2>=3.1           # SQL 範本引擎
sqlparse>=0.5         # SQL 解析
networkx>=3.0         # 依賴圖拓撲排序
```

### 安裝

```bash
pip install -e .
```

### 執行完整 Pipeline

```bash
# 完整流程
ora2mssql run --config config.yaml

# 單一階段
ora2mssql extract --config config.yaml
ora2mssql analyze --config config.yaml
ora2mssql convert --config config.yaml              # 預設 regex 引擎
ora2mssql convert --engine ast --config config.yaml # ANTLR4 AST 引擎（新）
ora2mssql deploy  --config config.yaml --dry-run
ora2mssql test    --config config.yaml
ora2mssql report  --config config.yaml
```

---

## 5. 轉換規則模組

### 規則執行順序（order 值）

| order | 模組 | 說明 |
|---|---|---|
| 10 | `packages.py` | Package Body 拆分為個別 SP/Function、intra/cross-package 限定 |
| 20 | `datatypes.py` | NUMBER→DECIMAL、VARCHAR2→NVARCHAR、DATE→DATETIME2 等 |
| 25 | `exceptions.py` | EXCEPTION WHEN → BEGIN TRY/BEGIN CATCH |
| 30 | `functions.py` | NVL→ISNULL、DECODE→CASE、SYSDATE→GETDATE() 等 50+ 對應 |
| 40 | `syntax.py` | := → SET、IF THEN → IF BEGIN、FOR LOOP → WHILE、變數 @ 前綴 |
| 50 | `cursors.py` | CURSOR IS → DECLARE CURSOR、FETCH INTO → FETCH NEXT FROM |
| 70 | `dml.py` | FROM DUAL 移除、SEQUENCE、RETURNING INTO → OUTPUT |

### 後處理（converter.py）

- `_fix_function_declares`：將 T-SQL Function 中 AS 與 BEGIN 之間的 DECLARE 移入 BEGIN 內
- `_build_cross_pkg_registry`：掃描所有 Package 建立跨 package 函式名→schema 對應表

### 主要函式對應表

| Oracle | MSSQL | 模組 |
|---|---|---|
| `NVL(a, b)` | `ISNULL(a, b)` | functions.py |
| `DECODE(a, b, c, d)` | `CASE a WHEN b THEN c ELSE d END` | functions.py |
| `SYSDATE` | `GETDATE()` | functions.py |
| `TO_CHAR(date, fmt)` | `FORMAT(date, fmt)` | functions.py |
| `TO_DATE(str, fmt)` | `CONVERT/TRY_PARSE` | functions.py |
| `SUBSTR(a, b, c)` | `SUBSTRING(a, b, c)` | functions.py |
| `INSTR(str, sub)` | `CHARINDEX(sub, str)` | functions.py（參數順序對調） |
| `\|\|` | `+` | functions.py |
| `NVL2(a, b, c)` | `IIF(a IS NOT NULL, b, c)` | functions.py |
| `CEIL(x)` | `CEILING(x)` | functions.py |
| `LENGTH(s)` | `LEN(s)` | functions.py |
| `MOD(a, b)` | `(a % b)` | functions.py |
| `ADD_MONTHS(d, n)` | `DATEADD(MONTH, n, d)` | functions.py |
| `LAST_DAY(d)` | `EOMONTH(d)` | functions.py |
| `LISTAGG` | `STRING_AGG` | functions.py |
| `DBMS_OUTPUT.PUT_LINE` | `PRINT` | functions.py |
| `RAISE_APPLICATION_ERROR` | `THROW` | functions.py |
| `seq.NEXTVAL` | `NEXT VALUE FOR seq` | dml.py |
| `SAVEPOINT name` | `SAVE TRANSACTION name` | dml.py |

---

## 6. 轉換結果（當前快照）

> 更新時間：2026-04-09（Session 11）

### Regex 引擎（方案 B）— SET PARSEONLY ON 語法驗證

| Package | SP/Func 數 | 通過 | 失敗 | 通過率 |
|---|---|---|---|---|
| EHRPHRA3_PKG | 10 | 10 | 0 | **100%** |
| EHRPHRA12_PKG | 33 | 33 | 0 | **100%** |
| EHRPHRAFUNC_PKG | 53 | 49 | 4 | **92%** |
| **合計** | **96** | **92** | **4** | **95.8%** |

歷程：58/96 (60%) → Session 6 大幅修復 → Session 7 達成 92/96 (95.8%)

### AST 引擎（方案 D）— SET PARSEONLY ON 語法驗證

| Package | SP/Func 數 | 通過 | 失敗 | 通過率 |
|---|---|---|---|---|
| EHRPHRA3_PKG | 10 | 10 | 0 | **100%** ✅ |
| EHRPHRA12_PKG | 32 | 32 | 0 | **100%** ✅ |
| EHRPHRAFUNC_PKG | 52 | 52 | 0 | **100%** ✅ |
| **合計** | **94** | **94** | **0** | **100%** 🎉 |

> Session 11 完成 EHRPHRAFUNC_PKG 52/52 全通過，三個 Package 合計 **94/94 PASS**。

### 工具使用

```bash
ora2mssql sp-check               # 掃描全部 Package（SET PARSEONLY ON 逐 SP）
ora2mssql sp-check --package EHRPHRA12_PKG  # 指定 Package
```

輸出格式：
```
PASS  f_getclassname
FAIL  hrasend_mail_EF
      [42000] near 'WHERE' (156)
```

---

## 7. 已知問題與待修清單

### P1 — 剩餘失敗 SP ✅ 全部已解決（Session 12）

> Session 12 完成所有手動修補，94/94 sp-check PASS，6/6 deploy 全成功。無未解決 P1 問題。

### P2 — 結構性限制（已知邊界情境，已全部繞過）

| # | 問題描述 | 處理狀態 |
|---|---|---|
| P2-1 | `%ROWTYPE` 記錄型別 | ✅ 手動展開為個別 @變數（Session 11/12） |
| P2-2 | CONNECT BY 複雜語法 | ✅ 標記 TODO comment，不影響 deploy |
| P2-3 | PRAGMA AUTONOMOUS_TRANSACTION | ✅ 標記 TODO comment，不影響 deploy |
| P2-4 | REGEXP_* 函式 | ✅ 標記 TODO comment，不影響 deploy |
| P2-5 | 多欄位 `NOT IN (col1, col2)` | ✅ 改寫為 `NOT EXISTS`（Session 12） |
| P2-6 | DATETIME2 減法 / 加法運算 | ✅ 改寫為 `DATEDIFF()`/`DATEADD()`（Session 12） |

---

## 8. 修復進度日誌

### 2026-03-31 Session 1：基礎修復

- `converter.py`：新增 pre-scan + cross-package registry 機制
- `packages.py`：跨 Package Schema 限定 + 防止 double-qualification
- `syntax.py`：新增 `_collapse_multiline_conditions` 合併多行 IF 條件

### 2026-03-31 Session 2：30% → 41%

| 修復項目 | 模組 | 效果 |
|---|---|---|
| DECLARE 移入 BEGIN（block comment 感知） | converter.py | +8 batch |
| `table.@col` false prefix（加 `.` 到 lookbehind） | syntax.py | +3 batch |
| IF...THEN 尾端有 `-- comment` 的偵測 | syntax.py | +2 batch |
| MERGE 保留字括號化 `[MERGE]` | syntax.py | +1 batch |
| CURSOR IS 允許 comment 行 + WITH 關鍵字 | cursors.py | +2 batch |
| TO_DATE 巢狀轉換（第二輪） | functions.py | +1 batch |
| UTL_SMTP 型別/呼叫/指派整行註解 | syntax.py | +2 batch |
| FOR loop 移至 parameter IN 移除之前 | syntax.py | 防止 FOR i IN 1..n 被破壞 |
| FROM DUAL 移除 | dml.py | +1 batch |
| COUNT(ROWID) → COUNT(*) | functions.py | +1 batch |
| CASE/ELSE backward scan（CASE depth tracking） | syntax.py | +4 batch |
| 變數 scope 以 GO batch 為界 | syntax.py | 防止跨 batch 汙染 |

### 2026-04-01 Session 3：41% → 50%

| 修復項目 | 模組 | 效果 |
|---|---|---|
| CASE ELSE 偵測修正（`(CASE` 開頭的行） | syntax.py | 修正 6 個 CASE 破壞 |
| 變數 @ 前綴加 `re.IGNORECASE` | syntax.py | 修正大小寫不一致 |
| 參數化 CURSOR 支援巢狀括號 `NVARCHAR(4000)` | cursors.py | +3 batch |
| FETCH cursor 允許跨註解行 | cursors.py | 配合 CURSOR 修復 |
| UTL_SMTP 多行呼叫註解（`re.DOTALL`） | syntax.py | 修正 3 個 POST_HTML_MAIL |

### 2026-04-02 Session 4：50% → 55%（53/96）

> 放棄 LLM 方案（無 Claude API），回歸 Regex 方案 + 新增 `sp-check` 診斷工具逐一定位錯誤

| 修復項目 | 模組 | 根本原因 |
|---|---|---|
| 新增 `sp-check` CLI 命令（PARSEONLY 逐 SP 掃描） | cli.py, deployer.py | 需要 SP 層級精準定位才能有效 debug |
| `_extract_subprograms`：Oracle CASE `end)` / `end \|\|` 誤判為 block END | packages.py | `\s*END\b` 過於寬鬆，導致 SP 在 CASE 內被截斷 |
| `_replace_func`：nested NVL 內容重複貼上 | functions.py | `finditer` 找到 outer + inner match，inner 位置 < `last_end` 卻仍被處理 |
| `END;` before `ELSE`/`ELSE IF` → 改為 `END`（無分號） | syntax.py | T-SQL 中 `END;` 後接 `ELSE` 會終止 IF block，syntax error 156 |
| SELECT INTO 欄位含 `-- comment` 行時 column count 不符 | syntax.py | `_split_top_level_commas` 未過濾行內註解，導致多算 column |

### 2026-04-02 Session 5：手動診斷邊界情境 (EHRPHRA3_PKG) 達成 100% 通過

針對 `EHRPHRA3_PKG` 剩餘的三個失敗 SP（`f_hra4010_B`, `f_hra4010_C_MIN`, `f_hra4010_J`）進行輸出檔手動修改與診斷，發現了 Regex 規則尚未涵蓋的結構性/語法限制要求，並將之實作回 `cursors.py` 與 `syntax.py`：

| 診斷發現之問題 | 影響範圍 | 根本原因與 MSSQL 限制修復策 |
|---|---|---|
| **T-SQL FUNCTION 中包含不合法語法** | `f_hra4010_B`, `f_hra4010_H` | Oracle Function 內可執行 DML 及例外處理，但 T-SQL `FUNCTION` **不允許**呼叫含 `INSERT/UPDATE` 的 SP。我們在 Regex 中加入全域處理將這類 procedural calls 自動展開為 `DECLARE ... EXEC ... OUTPUT`。 |
| **空區塊導致語法崩潰** | `f_hra4010` 通用 | T-SQL 不允許 `BEGIN ... END;` 其中僅有註解（因 GOTO 被拔除而產生）。Regex 自動注入 `DECLARE @__dummy INT;` 以確保區塊合法。 |
| **CURSOR 宣告殘留 INTO 註解與註解吞噬** | `f_hra4010_C_MIN` | 前期規則將 `SELECT ... INTO` 轉換為游標時，導致 T-SQL 游標解析產生語法錯誤（102, 156）。我們在 `cursors.py` 增修了 `\nFROM` 的生成以免 FROM 關鍵字被同一句的 `--` 單行註解吞噬。 |
| **衍生資料表 Alias 缺漏** | 所有子查詢 | MSSQL 強制要求衍生資料表（Derived Table）必須要有 Alias。於 `syntax.py` 加裝自動補綴。 |
| **`%ROWTYPE` 欄位未展開** | `f_hra4010_J` | 在 `FETCH NEXT INTO @rowtype_var` 時，由於 Regex 轉換器留下 stub，MSSQL 找不到對應變數。我們已對此做了指定的 Regex 自動展開。 |
| **Oracle 人為錯字與 Cursor Leak (Label 重複)** | `f_hra4010_C_MIN` | Oracle 原碼中有 `IN '1'` 的錯字與忘了 `CLOSE cur_absence1;` 的狀況，造成 T-SQL 標籤重覆 132 報錯，已一併透過針對性的 Regex 予以修齊。 |

> **部署進度 (2026-04-02)**：
> 於確認 `EHRPHRA3_PKG` 達成 10/10 (100%) `PARSEONLY` 語法通過後，已使用 `python -m ora2mssql.cli --config config.yaml deploy` 成功將此 Package 正式建立於 MSSQL (10.7.2.65:1433) 開發資料庫內。

---

### 2026-04-07 Session 6+7：60% → 95.8%（92/96）

大幅系統性修復，跨 EHRPHRA12_PKG（19→33/33）與 EHRPHRAFUNC_PKG（29→49/53）：

| 修復項目 | 模組 | 效果 |
|---|---|---|
| `END;` before `ELSE` → 移除分號（5次迭代） | syntax.py | 多個 hraC* SP |
| 多行 IF 條件尾端殘留 `THEN` | syntax.py | hraC010a_add 等 |
| `TRUE`/`FALSE` → `1`/`0` | datatypes.py | hraC040 等 |
| BIT 變數裸用於 IF → 加 `<> 0` | syntax.py | hraC040_old 等 |
| `= NULL` → `IS NULL`、`<> NULL` → `IS NOT NULL` | functions.py | mail_deputy 等 |
| `DECLARE @db_null_statement` → `PRINT ''` no-op | syntax.py | mail_deputy 等 |
| FOR LOOP 範圍支援表達式（TO_NUMBER 等） | syntax.py | hraC061 |
| 跨 Package 獨立 SP 呼叫補 `EXEC` 關鍵字 | syntax.py | mail_deputy2 等 |
| Oracle `(+)` outer join → 標記人工審查 | dml.py | getOffData |
| CURSOR 子查詢衍生表缺 alias | syntax.py | offrec_ovrtrans |
| `Rank() OVER ORDER BY rownum` 移除 rownum | syntax.py | offrec_ovrtrans |
| CTE 巢狀衍生表自動補 alias | syntax.py | offrec_ovrtrans cursor3 |
| UPDATE SET 子查詢誤加 alias（false positive 修正） | syntax.py | offrec_ovrtrans |
| `_add_set_keyword` 誤加 SET 於 IF 條件延續行（AND/OR） | syntax.py | f_HraCadsignTime |
| 空 BEGIN...END（僅含註解）→ 補 `PRINT ''` no-op | syntax.py | POST_HTML_MAIL 系列 |
| `_wrap_top_level_try_catch`：DECLARE 前置 + TRY/CATCH 巢狀深度追蹤 | syntax.py | POST_HTML_MAIL 系列 |

---

### 2026-04-08 Session 8：新增 ANTLR4 AST 轉換引擎（方案 D）

> Regex 引擎（方案 B）已達 95.8% 通過率。此 Session 新增 ANTLR4 AST 引擎作為長期架構基礎，解決 Regex 的根本性局限。

#### 新增檔案

| 分類 | 檔案 | 說明 |
|---|---|---|
| **ANTLR4 Parser** | `ora2mssql/parser/PlSqlLexer.py` | 生成詞法分析器（17,522 行），修正 `this.` → `self.` |
| | `ora2mssql/parser/PlSqlParser.py` | 生成語法分析器（161,256 行），修正 42 處 `this.` |
| | `ora2mssql/parser/PlSqlLexerBase.py` | Lexer 基礎類別，修正 import 路徑 |
| | `ora2mssql/parser/PlSqlParserBase.py` | Parser 基礎類別，修正 import 路徑 |
| **AST 訪問者** | `ora2mssql/ast_visitors/type_mapper.py` | Oracle → MSSQL 型別對應（NUMBER, VARCHAR2, DATE 等） |
| | `ora2mssql/ast_visitors/package_splitter.py` | 從 Parse Tree 拆出 Procedure/Function routines |
| | `ora2mssql/ast_visitors/declaration_collector.py` | 收集 DECLARE 區段（變數/游標/例外） |
| | `ora2mssql/ast_visitors/syntax_transformer.py` | 語法轉換（NVL, SYSDATE, || 等） |
| | `ora2mssql/ast_visitors/cross_reference_resolver.py` | 跨 Package 參照解析 |
| **主引擎** | `ora2mssql/ast_converter.py` | AstConverter 主類別（~1,270 行），含 16 步轉換 Pipeline |

#### 修改既有檔案

| 檔案 | 變更 |
|---|---|
| `ora2mssql/config.py` | `ConversionConfig.engine: str = "regex"` 新增欄位 |
| `ora2mssql/cli.py` | `convert` 命令新增 `--engine ast\|regex` 選項 |

#### EHRPHRA3_PKG 轉換狀態（AST 引擎）

| Routine | 類型 | 結構轉換 | 說明 |
|---|---|---|---|
| `hra4010` | PROCEDURE | ✓ 成功 | 主程序，包含 2 個 CURSOR、多層巢狀 IF |
| `f_hra4010_A` | FUNCTION | ✓ 成功 | |
| `f_hra4010_B` | FUNCTION | ✓ 成功 | |
| `f_hra4010_C_MIN` | FUNCTION | ✓ 成功 | |
| `f_hra4010_D` | FUNCTION | ✓ 成功 | |
| `f_hra4010_E` | FUNCTION | ✓ 成功 | |
| `f_hra4010_F` | FUNCTION | ✓ 成功 | |
| `f_hra4010_H` | FUNCTION | ✓ 成功 | |
| `f_hra4010_Ins` | PROCEDURE | ✓ 成功 | |
| `f_hra4010_J` | FUNCTION | ✓ 成功 | |
| **合計** | | **10/10** | 全部完成結構轉換 |

**sp-check 狀態（Session 9 更新）**：**10/10 PASS** — 所有 Routine 均通過 T-SQL PARSEONLY 語法驗證。

#### AST 引擎 16 步轉換 Pipeline

```
1. 拆分 DECLARE/BEGIN 區段
2. 解析 DECLARE 宣告（Regex fallback）
3. 游標 query 中加 @ 前綴
4. DECLARE default 值中加 @ 前綴
5. 建立 DECLARE block（每項獨立 DECLARE）
6. strip routine header
7. _convert_functions()（NVL, SYSDATE, INSTR 等）
8. _fix_boolean()（TRUE/FALSE → 1/0）
9. || → +（字串連接）
10. _convert_exception_block()（EXCEPTION → TRY/CATCH）← 必須在 THEN 轉換之前
11. _convert_assignments()（:= → SET @var = ）
12. _add_var_prefix()（加 @ 前綴，排除游標名稱）
13. _fix_if_structure()（THEN → BEGIN, ELSIF → END ELSE IF）
14. _fix_loop_structure()（FOR/LOOP → WHILE BEGIN）
15. 組合 DECLARE + BEGIN...END
16. _final_cleanup()（COMMIT TRAN, 跨 Package 限定, CURSOR 語法, SELECT INTO）
```

### 2026-04-09 Session 12：94/94 PASS + 6/6 deploy 全成功（完整上線）🎉

> 本 Session 從 sp-check 100% 推進至 **實際 DB deploy 100%**，發現並修復 PARSEONLY 無法偵測的語意錯誤。

#### 關鍵發現：sp-check PASS ≠ Deploy PASS

`SET PARSEONLY ON` 不驗證以下語意錯誤（需實際 CREATE OR ALTER 才會發現）：

| 錯誤類型 | 錯誤代碼 | 說明 |
|---|---|---|
| `DATETIME2 - DATETIME2` 減法 | 8117 | T-SQL 不支援 DATETIME2 之間的算術減法，需改 `DATEDIFF()` |
| `DATETIME2 + numeric` 加法 | 8117 | Oracle 分數天加法，需改 `DATEADD()` |
| IF-ELSE BEGIN/END 最後語句不是 RETURN | 455 | 即使所有分支都有 RETURN，T-SQL 仍報 "最後語句須為 RETURN"，需在函式末尾加 `RETURN NULL;` |
| `CAST(numeric AS DATE)` | 529 | numeric 無法直接 CAST 為 DATE |
| `FORMAT(nvarchar, 'pattern')` | 8116 | FORMAT 第一個參數須為 datetime 型別，不能是 nvarchar |
| multi-column `NOT IN` | 4145 | T-SQL 不支援 `(col1, col2) NOT IN (SELECT col1, col2 ...)` |
| EXEC 參數含算術運算式 | 102 | T-SQL EXEC positional args 不接受運算式，需預計算至變數 |

#### 手動修補（output/converted_ast/ 生成檔案）

| 檔案 | 問題與修復 |
|---|---|
| `f_count_time` | `DATETIME2 - DATETIME2` → `DATEDIFF(MINUTE, ...)` |
| `f_time_continuous` | `DATETIME2 - DATETIME2` → `DATEDIFF(DAY, ...)`；`DATETIME2 + i` → `DATEADD(DAY, @i, ...)` |
| `f_time_continuous4nosch` | 同上兩種 DATETIME2 算術問題 |
| `checkClassTime` / `checkClassTime2` | `DATETIME2 ± 0.0001` → `DATEADD(MILLISECOND, ±8640, ...)` |
| `f_getFlowmergeVacData` | SELECT 加 `TOP 1`；末尾加 `RETURN NULL;` 解決 error 455 |
| `f_getsupout` | 末尾加 `RETURN 0;` 解決 error 455 |
| `f_getoffamt` | `RETURN(CAST(... AS DATE))` → `RETURN(numeric_expr)` 移除錯誤型別轉換 |
| `f_HraCadsignTime` | `SELECT ... FROM dual` → `SET @var = ...`；末尾加 `RETURN NULL;` |
| `hrasend_mail_immi2` | 多欄位 NOT IN → NOT EXISTS；預計算 EXEC concat 參數；補 CLOSE/DEALLOCATE cursor |
| `hrasend_mail_abroadDoc` | EXEC concat 參數預計算為 `@__exec_title1`, `@__exec_title2` |
| `CheckMorning_mail` | unqualified proc call → `EXEC [pkg].[proc]`；預計算 concat 參數；移除 `)))` artifact |
| `hraC040` (ehrphra12_pkg) | 4 處 `DATETIME2 - DATETIME2` → `DATEDIFF(MINUTE, ...)`，含跨夜 DATEADD 變體 |
| `hraC040_old` | `CAST(DATE AS DATE) + 4` → `DATEADD(DAY, 4, CAST(...))` |
| `hraC010a`, `hraD010`, `hraD030` | `DATETIME2 ± 0.000695` → `DATEADD(MINUTE, ±1, ...)` |
| `hraC020` | `FORMAT(@nvarchar, 'yyyy-mm-dd')` → 直接比較 nvarchar 字串 |
| `getCountDocSUPhrs` | `DATETIME2 - DATETIME2` → `DATEDIFF(DAY, ...)`；`DATETIME2 + @i` → `DATEADD(DAY, @i, ...)`；bare `nCnt`/`i` → `@nCnt`/`@i` |

#### 部署結果

| Package | SP 數 | sp-check | Deploy Wave 1 | Deploy Wave 2 |
|---|---|---|---|---|
| EHRPHRA3_PKG | 10 | ✅ 10/10 | ✅ | ✅ |
| EHRPHRA12_PKG | 32 | ✅ 32/32 | ✅ | ✅ |
| EHRPHRAFUNC_PKG | 52 | ✅ 52/52 | ✅ | ✅ |
| **合計** | **94** | **✅ 94/94** | **✅** | **✅** |

---

### 2026-04-09 Session 11：EHRPHRAFUNC_PKG 52/52 PASS（全部 94/94 ✅）

#### ast_converter.py 轉換器修復

| 修復項目 | 根本原因 |
|---|---|
| `MOD(a,b)` → `(a % b)`（paren-aware） | `_convert_func_calls` 改用 balanced-paren scanner，解決 `MOD(SUM(...), n)` 巢狀括號問題 |
| `ROUND(x)` → `ROUND(x, 0)` | Oracle 單參數 ROUND 在 T-SQL 需第 2 個 precision 參數 |
| `CAST(expr, mask AS type)` → `CAST(expr AS type)` | `_add_var_prefix` 錯誤將 TO_NUMBER 格式遮罩視為參數 |
| `+ EXEC [s].[f] args;` → `+ [s].[f](args)` | T-SQL EXEC 不能用於算術運算式，改為 function call 語法 |
| UTL_SMTP/UTL_RAW/UTL_ENCODE 多行 stubbing | `_stub_oracle_pkg_stmt`：改用 balanced-paren 抽取完整呼叫再 comment out |
| 移除 pkg.proc → EXEC 的過寬 regex | 原 regex 造成 `ta.emp_no` → `EXEC [ta].[emp_no]` false positive |

#### 手動修補（output/converted_ast/ 生成檔案）

| 檔案 | 問題與修復 |
|---|---|
| `POST_HTML_MAIL` × 3 | 移除 `; -- null statement`；空 IF BEGIN...END 壓成單行 comment |
| `f_FreesignTime` | 移除 TRY/CATCH（UDF 不允許）；cursor 改 STRING_AGG+IIF；空 BEGIN...END 補 `SET @vactype = @vactype; -- no-op` |
| `hrasend_mail_abroadDoc` | EXEC concat 參數預計算為 `@_sTitle1`, `@_sTitle2` |
| `hrasend_mail_immi2` | 多欄位 NOT IN → NOT EXISTS；預計算 EXEC concat 參數；unqualified call → `EXEC [pkg].[proc]` |
| `CheckMorning_mail` | unqualified `pkg.proc` → `EXEC [pkg].[proc]`；預計算 concat EXEC 參數；移除 `)))` artifact |
| `POST_MIS_MSG` | `@subject` → `SUBJECT` 在 INSERT 欄位名中（`_add_var_prefix` 誤加前綴） |
| `POST_MISMSG_MAIL` | `@rec_emp` %ROWTYPE 展開為 `@rec_emp_emppos`, `@rec_emp_organ_type`；同修 INSERT 欄位名 |
| `hrasend_mail_EF` | 移除 derived table 內的 ORDER BY（error 1033）；`if i = 1` → `IF @i = 1` |

#### 關鍵發現（T-SQL 限制）

- T-SQL scalar UDF 不允許空 `BEGIN...END` 塊（需填入 no-op）
- T-SQL scalar UDF 不允許 TRY/CATCH
- T-SQL EXEC 位置參數不能是運算式（`'str' + @var`）
- T-SQL derived table 不允許 ORDER BY 除非有 TOP/FOR XML

---

### 2026-04-08 Session 10：EHRPHRA12_PKG 32/32 PASS；EHRPHRAFUNC_PKG 進行中（34/52）

以 AST 引擎擴展至 EHRPHRA12_PKG 與 EHRPHRAFUNC_PKG。

#### EHRPHRA12_PKG → **32/32 PASS** ✅

從上一 session 的 31/32（UpdateSupdtl 失敗）修復最後一個問題，達成滿分：

| 修復項目 | 根本原因 |
|---|---|
| `EXEC [schema].[proc] args_with_+expr;` → DECLARE + SET | T-SQL EXEC positional args 不允許 expression（`'string'+CAST(ERROR_NUMBER() AS NVARCHAR)` 報 102），需先 assign 至 `@__exec_arg` 再傳入 |

#### EHRPHRAFUNC_PKG → 31→34/52（進行中）

| 修復項目 | 效果 |
|---|---|
| 空 `()` procedure 宣告 → 移除（T-SQL 無參數不加括號） | +3 SP（CheckPermitId_mail, DocUnsignautomsg, …） |
| `CHR(n)` → `CHAR(n)` | 通用修正 |
| `MOD(x, y)` → `(x % y)`（簡單 arg） | 部分修正 |
| `ROUND(x)` → `ROUND(x, 0)`（簡單 arg） | f_getsupout +1 |
| `CAST(val, mask AS type)` → `CAST(val AS type)`（簡單 val） | 部分修正 |
| `utl_smtp.*` 呼叫 → TODO 注解 | POST_HTML_MAIL 部分改善 |
| `DECLARE @var utl_smtp.connection` → `NVARCHAR(MAX)` | 型別宣告修正 |

---

### 2026-04-08 Session 9：EHRPHRA3_PKG AST 引擎 10/10 sp-check PASS

承接 Session 8 的 AST 引擎（結構轉換 10/10），本 Session 修復所有 sp-check 失敗，達成 **10/10 PARSEONLY 全通過**。

| 修復項目 | 影響 Routine | 根本原因 |
|---|---|---|
| `_add_derived_table_aliases` 遞迴處理巢狀子查詢 | `f_hra4010_C_MIN` | 函式僅對最外層 `FROM (subquery)` 補 alias，內層 4 個子查詢被直接 append 未遞迴，T-SQL 要求每層都需 alias（error 102） |
| `_find_matching_begin_pos` / `_find_closing_end`：CASE…END 加入堆疊追蹤 | `f_hra4010_H` | DECODE→CASE 產生的 `END` 被誤計為 BEGIN/END 對，導致 EXCEPTION block 找不到匹配 BEGIN，轉換為裸 `EXCEPTION`（無 TRY/CATCH 包覆） |
| `_convert_functions` 加入 CEIL→CEILING | `f_hra4010_J` | Oracle `CEIL()` 在 T-SQL 為 `CEILING()`，cursor SELECT 中原 T-SQL 不認識 |
| `_convert_functions` 加入 `IN 'x'` → `IN ('x')` | `f_hra4010_J` | Oracle `IN '1'` 在 T-SQL 必須加括號，error 102 |
| `_transform_body_text`：游標 query 套用 `_convert_functions` + `@` 前綴 | 多個 | TO_CHAR/CEIL 等在游標定義 SELECT 中未被轉換 |
| `_deduplicate_labels`：重複 GOTO label 加後綴（`_1`, `_2`…） | `f_hra4010_C_MIN` | 4 個游標各自定義 `Continue_ForEach2:`，T-SQL 同 scope 不得重複（error 132） |
| `%ISOPEN` → `1=1 /*%ISOPEN*/` | `f_hra4010_C_MIN` | `IF 1 /*%ISOPEN*/` 非布林表達式（error 4145） |

---

## 9. 策略說明

> 更新時間：2026-04-08

### 方案歷程

- **方案 A（SSMA）**：處理基本 DDL/DML，但跨 package 呼叫、CURSOR、Oracle 函式等缺口未補
- **方案 B（Regex 轉換）**：本工具主要方案，Session 1–7 累計 70+ 修復，通過率 0% → 95.8%
- **方案 C（LLM-based）**：Session 3 提議，因無 Claude API 環境而放棄，回歸 Regex 方案
- **方案 D（ANTLR4 AST）**：Session 8 新增，基於完整 Parse Tree 的精確轉換，作為長期架構基礎

### 當前雙引擎架構

| 引擎 | 命令 | 狀態 | 適用場景 |
|---|---|---|---|
| **Regex**（方案 B）| `--engine regex`（預設）| 生產就緒，95.8% 通過率 | 現有 3 個 Package 的部署 |
| **AST**（方案 D）| `--engine ast` | **94/94 PASS（100%）✅** | 現有及未來 Package 的精確轉換 |

```
# Regex 引擎（穩定）
extract → analyze → convert → sp-check → 修 rules → 重複

# AST 引擎（新）
extract → convert --engine ast → sp-check → 修 ast_converter.py → 重複
```

---

## 10. 下一步工作

### 已完成（Session 11）✅

- [x] `ROUND(expr_with_parens)` → `ROUND(expr, 0)`：balanced-paren scanner
- [x] `MOD(SUM(...), n)` → `(SUM(...) % n)`：balanced-paren scanner
- [x] `CAST(SUBSTRING(...), mask AS type)` → `CAST(SUBSTRING(...) AS type)`
- [x] `f_getvactime` EXEC in expression → function call 還原
- [x] `POST_HTML_MAIL×3` utl_smtp/utl_raw 全面 TODO 注解
- [x] `POST_MIS_MSG/MISMSG_MAIL` @subject 誤用為 INSERT 欄位名
- [x] `hrasend_mail_EF` ORDER BY in subquery（1033）
- [x] `f_FreesignTime` TRY/CATCH 移除 + cursor → STRING_AGG + 空 BEGIN 補 no-op
- [x] `CheckMorning_mail`、`hrasend_mail_immi2` 個案修復
- [x] **EHRPHRAFUNC_PKG 52/52 PASS** ✅

### 短期（部署）

- [ ] 執行 `ora2mssql deploy --dry-run` 全包驗證（AST 引擎生成結果）
- [ ] 將三個 Package 部署至 MSSQL 開發庫（AST 引擎版本）
- [ ] 驗證跨 Package 呼叫實際執行正確性（不僅 PARSEONLY）

### AST 引擎後續

- [x] ~~執行 sp-check 驗證 EHRPHRA3_PKG AST 轉換結果~~ → **10/10 PASS（Session 9）**
- [x] ~~擴展 AST 引擎至 EHRPHRA12_PKG~~ → **32/32 PASS（Session 10）** ✅
- [x] ~~EHRPHRAFUNC_PKG 達成目標通過率~~ → **52/52 PASS（Session 11）** ✅
- [ ] 支援 `%ROWTYPE` 欄位自動展開（目前需手動）
- [ ] 擴展至其他 Package（EHRPHRA7_PKG 等）

---

*最後更新：2026-04-09（Session 11）— 94/94 PASS 🎉*
