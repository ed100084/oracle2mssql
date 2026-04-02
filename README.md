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

> 更新時間：2026-04-02（Session 5）
>
> **測試方式升級**：新增 `ora2mssql sp-check` 命令，逐一對每個 SP/Function 做 SET PARSEONLY ON，取代整個 Package 一次測試，可精確定位哪個 SP 失敗及原因。

### 新工具：`sp-check`

```bash
ora2mssql sp-check               # 掃描全部 Package
ora2mssql sp-check --package EHRPHRA3_PKG  # 指定 Package
```

每個 SP 獨立測試，輸出格式：
```
PASS  f_getclassname
FAIL  hraC010a
      [42000] near 'ELSE' (156)
```

### SET PARSEONLY ON 語法驗證（SP 級別）

| Package | SP/Func 數 | 通過 | 失敗 | 通過率 |
|---|---|---|---|---|
| EHRPHRA3_PKG | 10 | 10 | 0 | 100% |
| EHRPHRA12_PKG | 33 | 17 | 16 | 52% |
| EHRPHRAFUNC_PKG | 53 | 29 | 24 | 55% |
| **合計** | **96** | **56** | **40** | **58%** |

（Session 4 結束時：53/96 = 55%；Session 5 修復 EHRPHRA3_PKG 後：56/96 = 58%）

### 錯誤分類（40 個失敗 SP，Session 5 快照）

| 錯誤碼 | 數量 | 說明 |
|---|---|---|
| (102) syntax only | 15 | 含 SELECT INTO 變數未轉換、部分 assignment 語法 |
| (102)+(156) syntax+keyword | 12 | near 'THEN' 殘留（IF THEN 未完整轉換）、near 'FOR' |
| (156) keyword only | 3 | near 'ELSE'、near 'FOR' |
| (195) unrecognized | 2 | VARCHAR 被誤用為型別（應為 NVARCHAR） |
| (102)+(156)+(195) | 2 | 複合錯誤 |
| (4145) non-boolean | 2 | 非布林運算式被用在 IF 條件 |
| 其他複合 | 5 | 重複 label、undeclared var 等 |

---

## 7. 已知問題與待修清單

### P1 — 阻擋部署（Critical）

| # | 問題描述 | 影響 | 狀態 |
|---|---|---|---|
| P1-1 | SP 呼叫缺少 `EXEC` 關鍵字 | 所有跨 package SP 呼叫 | 待修 |
| P1-2 | `_add_set_keyword` 遺漏部分 `@var = expr;` | ~10 個 batch | 待修 |
| P1-3 | Oracle comma-join + ANSI JOIN 混用 | 4 個 hrasend_mail* | 已加 CROSS JOIN 轉換（待驗證） |

### P2 — 語法錯誤（High）

| # | 問題描述 | 影響 | 狀態 |
|---|---|---|---|
| P2-1 | CASE ELSE 被 `_convert_if_then` 誤轉為 IF ELSE | 已修正大部分，少數殘留 | 已修 |
| P2-2 | 變數 @ 前綴大小寫不敏感匹配 | ~8 個 batch | 已修 |
| P2-3 | 參數化 CURSOR 含 NVARCHAR(4000) 巢狀括號 | 4 個 batch | 已修 |
| P2-4 | UTL_SMTP 多行呼叫未完整註解 | 3 個 POST_HTML_MAIL | 已修 |
| P2-5 | FETCH cursor 跨註解行 | getOffhrs 系列 | 已修 |
| P2-6 | `%ROWTYPE` 記錄型別未展開 | 3 處 | 需人工處理 |

### P3 — 結構性問題（Medium）

| # | 問題描述 |
|---|---|
| P3-1 | `BEGIN TRY` 在 function 中需外包 `BEGIN...END` 包裝層 |
| P3-2 | CONNECT BY 複雜語法僅標記人工處理 |
| P3-3 | PRAGMA AUTONOMOUS_TRANSACTION 無直接對應 |
| P3-4 | REGEXP_* 函式無原生 MSSQL 對應 |

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

按優先順序排列：

### 立即（修復剩餘 43 個失敗 SP）

按 Session 4 快照的錯誤分類：

| 優先級 | 錯誤類型 | 數量 | 修改目標 |
|---|---|---|---|
| P1 | 接近 `'THEN'`（102） | 12 | `syntax.py` IF...THEN 多行/邊界條件 |
| P2 | 接近 `'FOR'`（102） | 3 | `syntax.py` FOR LOOP 轉換邊界 |
| P3 | 接近 `';'`（102）/ 其他語法 | 17 | SELECT INTO INTO clause 含註解行 |
| P4 | 重複標籤（132） | 1 | `syntax.py` FOR LOOP label 加 counter |
| P5 | VARCHAR 未識別（2715） | 2 | `syntax.py` VARCHAR → NVARCHAR 缺漏 |
| P6 | 非 boolean 條件（4145） | 2 | 手動 review：條件式缺 IS NULL / = |

具體立即修復項目：

- [x] SELECT INTO：INTO clause 含跨行 `--` 注解時 `@var` 清單截斷與 `FROM` 吞噬（`syntax.py` / `cursors.py` 已修復）
- [x] FOR LOOP：`label` 重複（同一 SP 有多個 FOR LOOP 生成相同 `Continue_ForEach`，已於 `syntax.py` 修復）
- [ ] VARCHAR → NVARCHAR 2715 錯誤
- [ ] IF...THEN：多行條件合併後仍有 `THEN` 殘留的邊界案例

### 短期

- [x] 升級 Python Regex 轉換器，解決 T-SQL Function 限制（自動展開 Procedural Call 及修正假 BEGIN 區塊）。
- [x] 強化 `cursors.py` 將 `SELECT /*INTO...*/ FROM` 游標中的註解正確移除或防吞噬。
- [x] 透過 `ora2mssql deploy` 成功將 100% 通過之 `EHRPHRA3_PKG` (10 個物件) 部署至 MSSQL 開發庫。
- [ ] 通過率達 80%+ 後執行 `ora2mssql deploy --dry-run` 全包驗證
- [x] 處理 `%ROWTYPE` 游標（`cur_otmsign` 已透過 Regex 自動化展開，剩餘待處理）

### 中期

- [ ] 建立 Git Repository 做版本控制
- [ ] 擴展轉換範圍至其他 HRP Schema Packages

---

*最後更新：2026-04-02*
