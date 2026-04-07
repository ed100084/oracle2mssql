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
│   ├── cli.py                        # Click CLI 入口
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
ora2mssql convert --config config.yaml
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

> 更新時間：2026-04-07（Session 7）

### SET PARSEONLY ON 語法驗證（SP 級別）

| Package | SP/Func 數 | 通過 | 失敗 | 通過率 |
|---|---|---|---|---|
| EHRPHRA3_PKG | 10 | 10 | 0 | **100%** |
| EHRPHRA12_PKG | 33 | 33 | 0 | **100%** |
| EHRPHRAFUNC_PKG | 53 | 49 | 4 | **92%** |
| **合計** | **96** | **92** | **4** | **95.8%** |

歷程：58/96 (60%) → Session 6 大幅修復 → Session 7 達成 92/96 (95.8%)

### 剩餘 4 個失敗 SP（均在 EHRPHRAFUNC_PKG）

| SP | 錯誤 | 根本原因 |
|---|---|---|
| `f_FreesignTime` | OUTPUT 參數型別 + `%ROWTYPE` | `rec_evcdata %ROWTYPE` 未展開為個別變數 |
| `hrasend_mail_immi2` | 4145 非布林 + 102 | 多欄位 `NOT IN (col1, col2)` 子查詢語法 |
| `hrasend_mail_EF` | 1033 ORDER BY + 156 WHERE + 134 @i | 子查詢中含 ORDER BY；`@i` 重複宣告 |
| `POST_MISMSG_MAIL` | `%ROWTYPE` | `rec_emp %ROWTYPE` 未展開 |

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

### P1 — 剩餘失敗 SP（4 個，均需人工處理）

| SP | 問題 | 建議處理 |
|---|---|---|
| `f_FreesignTime` | `rec_evcdata %ROWTYPE` 未展開 | 手動展開欄位型別 |
| `hrasend_mail_immi2` | 多欄位 `NOT IN (col1, col2)` 子查詢 | 改寫為 `NOT EXISTS` 或 JOIN |
| `hrasend_mail_EF` | 子查詢 `ORDER BY` + `@i` 重複宣告 | 移除子查詢 ORDER BY；重構迴圈變數 |
| `POST_MISMSG_MAIL` | `rec_emp %ROWTYPE` 未展開 | 手動展開欄位型別 |

### P2 — 結構性限制（無 Regex 通用解）

| # | 問題描述 |
|---|---|
| P2-1 | `%ROWTYPE` 記錄型別：需依游標結構逐案展開為個別 @變數 |
| P2-2 | CONNECT BY 複雜語法：已標記人工處理 |
| P2-3 | PRAGMA AUTONOMOUS_TRANSACTION：無直接對應 |
| P2-4 | REGEXP_* 函式：無原生 MSSQL 對應 |

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

## 9. 策略說明

> 更新時間：2026-04-02

### 方案歷程

- **方案 A（SSMA）**：處理基本 DDL/DML，但跨 package 呼叫、CURSOR、Oracle 函式等缺口未補
- **方案 B（Regex 轉換）**：本工具主要方案，Session 1–4 累計 50+ 修復，通過率 0% → 55%
- **方案 C（LLM-based）**：Session 3 提議，因無 Claude API 環境而放棄，回歸 Regex 方案

### 當前採用方案

**方案 B（Regex）+ 診斷工具**：

```
extract → analyze → convert（regex rules）→ sp-check（PARSEONLY 逐 SP）→ 修 rules → 重複
```

`sp-check` 工具的加入使 debug 效率大幅提升：不需 full deploy，每次只需一次 MSSQL 連線即可掃描全部 SP 的語法正確性。

---

## 10. 下一步工作

### 立即（剩餘 4 個失敗 SP）

- [ ] `f_FreesignTime`、`POST_MISMSG_MAIL`：手動展開 `%ROWTYPE` 欄位型別
- [ ] `hrasend_mail_immi2`：改寫多欄位 NOT IN 子查詢
- [ ] `hrasend_mail_EF`：修復子查詢 ORDER BY + @i 重複宣告

### 短期

- [ ] 執行 `ora2mssql deploy --dry-run` 全包驗證（目前 95.8% 語法通過率）
- [ ] 將 EHRPHRA12_PKG、EHRPHRAFUNC_PKG 部署至 MSSQL 開發庫
- [ ] 擴展轉換範圍至其他 HRP Schema Packages

---

*最後更新：2026-04-07*
