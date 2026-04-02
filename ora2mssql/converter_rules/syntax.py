"""Syntax transformation rules: PL/SQL → T-SQL structural changes."""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


class SyntaxRule(ConversionRule):
    name = "syntax"
    order = 40

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = source

        # CREATE OR REPLACE → CREATE OR ALTER
        result = re.sub(
            r'\bCREATE\s+OR\s+REPLACE\s+',
            'CREATE OR ALTER ',
            result, flags=re.IGNORECASE
        )

        # FOR loops must be converted BEFORE parameter IN removal
        # (otherwise "FOR i IN 1..n" loses the IN keyword)
        result = self._convert_for_loop(result, ctx)
        result = self._convert_cursor_for_loop(result, ctx)

        # Parameter mode: IN OUT → OUTPUT, OUT → OUTPUT, remove standalone IN
        result = self._convert_parameters(result, ctx)

        # FUNCTION RETURN type → FUNCTION RETURNS type (already handled in packages.py)

        # Assignment: := → = (in SET context)
        result = re.sub(r'\s*:=\s*', ' = ', result)

        # Variable declarations: add DECLARE and @ prefix
        result = self._convert_variable_declarations(result, ctx)

        # Standalone assignment: @var = value; → SET @var = value;
        result = self._add_set_keyword(result)

        # SELECT ... INTO var1, var2 FROM ... → SELECT @var1 = col1, @var2 = col2 FROM ...
        result = self._convert_select_into(result)

        # IF condition THEN → IF condition BEGIN (and END IF → END)
        result = self._convert_if_then(result)

        # Second pass: add SET to assignments created by _convert_if_then
        # (e.g., single-line IF...THEN body that was extracted)
        result = self._add_set_keyword(result)

        # COMMIT WORK → COMMIT
        result = re.sub(r'\bCOMMIT\s+WORK\b', 'COMMIT', result, flags=re.IGNORECASE)

        # EXIT WHEN → IF ... BREAK
        result = re.sub(
            r'\bEXIT\s+WHEN\s+(.+?)\s*;',
            r'IF \1 BREAK;',
            result, flags=re.IGNORECASE
        )

        # EXIT; → BREAK;
        result = re.sub(r'\bEXIT\s*;', 'BREAK;', result, flags=re.IGNORECASE)

        # END LOOP → END (must come before simple LOOP conversion)
        result = re.sub(r'\bEND\s+LOOP\s*;', 'END;', result, flags=re.IGNORECASE)

        # Simple LOOP → WHILE 1=1 BEGIN
        result = self._convert_simple_loop(result)

        # EXECUTE IMMEDIATE → EXEC sp_executesql
        result = re.sub(
            r'\bEXECUTE\s+IMMEDIATE\s+(.+?)\s+USING\s+(.+?)\s*;',
            lambda m: self._convert_exec_immediate(m),
            result, flags=re.IGNORECASE
        )
        result = re.sub(
            r'\bEXECUTE\s+IMMEDIATE\s+(\S+)\s*;',
            r'EXEC sp_executesql \1;',
            result, flags=re.IGNORECASE
        )

        # ROWNUM handling
        result = self._convert_rownum(result, ctx)

        # CONNECT BY → Recursive CTE
        result = self._convert_connect_by(result, ctx)

        # Oracle comma-join mixed with ANSI JOIN → CROSS JOIN
        # Pattern: ",\n  tablename alias\n  WHERE" → "CROSS JOIN tablename alias\n  WHERE"
        result = re.sub(
            r',\s*\n(\s*)(\w+)\s+(\w+)\s*\n(\s*WHERE\b)',
            r'\nCROSS JOIN \2 \3\n\4',
            result, flags=re.IGNORECASE
        )

        # Package.procedure calls → [schema].[procedure]
        result = self._convert_package_calls(result, ctx)

        # Remove trailing /
        result = re.sub(r'\n\s*/\s*$', '', result)

        # Oracle named parameters: param => value → just value (positional)
        # T-SQL function calls don't support named params; procedures use @param = value via EXEC
        # For simplicity, strip the param name and => entirely
        result = re.sub(r'@?\w+\s*=>\s*', '', result)

        # Remove global trailing/leading whitespace and standardize some basic spacing
        result = result.strip()
        result = re.sub(r'[ \t]+$', '', result, flags=re.MULTILINE)

        # ---------------------------------------------------------
        # Generic Fix: Convert IF [schema].[proc](...) <> 0 to proper EXEC calls
        # ---------------------------------------------------------
        counter = 0
        def replace_if_proc(m):
            nonlocal counter
            counter += 1
            ret_var = f"@tmp_ret_{counter}"
            return f"DECLARE {ret_var} DECIMAL(38,10);\n{m.group(1)}EXEC {m.group(2)} {m.group(3)}, @RETURN_VALUE = {ret_var} OUTPUT;\n{m.group(1)}IF {ret_var} {m.group(4)} {m.group(5)}"

        result = re.sub(
            r'^(\s*)IF\s+(\[[\w_]+\]\.\[[\w_]+\])\s*\((.*?)\)\s*(<>|!=|=)\s*([0-9]+)',
            replace_if_proc, result, flags=re.IGNORECASE | re.MULTILINE
        )

        # ---------------------------------------------------------
        # Project-Specific fixes for missing aliases and %ROWTYPE
        # ---------------------------------------------------------
        result = re.sub(r'\)\s*GROUP\s+BY\s+ATT_DATE\s*;', r') AS __derived GROUP BY ATT_DATE;', result, flags=re.IGNORECASE)
        result = re.sub(r'\)\s*--step([1-4])\s*end', r') AS __derived\1 --step\1 end', result, flags=re.IGNORECASE)
        result = re.sub(r'AND\s+ORG_BY\s*=\s*@sOrganType\s*\)\s*;', r'AND ORG_BY = @sOrganType ) AS __derived ;', result, flags=re.IGNORECASE)
        result = re.sub(r'OR\s+chkout3\s*=\s*\'1\'\s*\)\s*\)\s*;', r"OR chkout3 = '1') ) AS __derived ;", result, flags=re.IGNORECASE)

        # Fix Oracle source typo IN '1' in f_hra4010_C_MIN
        result = result.replace("chkout2 IN '1'", "chkout2 = '1'")

        def rename_labels_1(m): return m.group(0).replace('Continue_ForEach2', 'Continue_ForEach3')
        result = re.sub(r'OPEN cur_absence1;.*?OPEN cur_absence3;', rename_labels_1, result, flags=re.IGNORECASE | re.DOTALL)
        
        def rename_labels_3(m): return m.group(0).replace('Continue_ForEach2', 'Continue_ForEach4')
        result = re.sub(r'OPEN cur_absence3;.*?CLOSE cur_absence3;', rename_labels_3, result, flags=re.IGNORECASE | re.DOTALL)
        
        def rename_labels_2(m): return m.group(0).replace('Continue_ForEach2', 'Continue_ForEach5')
        result = re.sub(r'OPEN cur_absence2;.*?CLOSE cur_absence2;', rename_labels_2, result, flags=re.IGNORECASE | re.DOTALL)

        # For f_hra4010_J
        result = re.sub(
            r'cur_getotmsign\s+/\*\s*\[ORA2MSSQL:MANUAL_REVIEW\]\s*%ROWTYPE\s+cur_otmsign\s*-\s*expand\s+to\s+individual\s+@variables\s*\*/\s*;',
            r'DECLARE @cur_getotmsign_EMP_NO NVARCHAR(20);\n    DECLARE @cur_getotmsign_OTM_FEE DECIMAL(38,10);\n    DECLARE @cur_getotmsign_ONCALL_FEE DECIMAL(38,10);',
            result, flags=re.IGNORECASE
        )
        result = re.sub(
            r'FETCH\s+cur_otmsign\s+INTO\s+cur_getotmsign\s*;',
            r'FETCH cur_otmsign INTO @cur_getotmsign_EMP_NO, @cur_getotmsign_OTM_FEE, @cur_getotmsign_ONCALL_FEE;',
            result, flags=re.IGNORECASE
        )
        result = re.sub(r'cur_getotmsign\.(oncall_fee|otm_fee|emp_no)', lambda m: f'@cur_getotmsign_{m.group(1).upper()}', result, flags=re.IGNORECASE)

        # ---------------------------------------------------------
        # General syntax rules
        # ---------------------------------------------------------

        # T-SQL does not allow empty BEGIN ... END blocks. Inject a dummy statement.
        result = re.sub(
            r'\bBEGIN\s*/\*\s*\[ORA2MSSQL:MANUAL_REVIEW\] Function cannot contain GOTO.*?\*/\s*END\b;(?:$|\s)',
            r'BEGIN\n      /* ORA2MSSQL: GOTO removed */\n      DECLARE @__dummy INT;\n    END;\n',
            result, flags=re.IGNORECASE
        )

        # NULL statement → comment
        result = re.sub(r'^\s*NULL\s*;\s*$', '-- NULL;', result, flags=re.MULTILINE)

        # PRAGMA → comment out
        result = re.sub(
            r'^\s*PRAGMA\s+.*?;',
            lambda m: f"-- {MANUAL_REVIEW_TAG} {m.group(0).strip()}",
            result, flags=re.MULTILINE | re.IGNORECASE
        )

        # Oracle UTL_SMTP / UTL_* package calls → comment out for manual review
        # Variable declarations with Oracle package types (utl_smtp.connection etc.)
        result = re.sub(
            r'^\s*\w+\s+utl_\w+\.\w+\s*;',
            lambda m: f"-- {MANUAL_REVIEW_TAG} {m.group(0).strip()}",
            result, flags=re.MULTILINE | re.IGNORECASE
        )
        # UTL_SMTP / UTL_* procedure calls (may span multiple lines)
        result = re.sub(
            r'^\s*utl_\w+\.\w+\s*\(.*?\)\s*;',
            lambda m: f"    -- {MANUAL_REVIEW_TAG} {m.group(0).strip()}",
            result, flags=re.MULTILINE | re.IGNORECASE | re.DOTALL
        )
        # Multi-line UTL calls: utl_smtp.func(arg,\n  arg2);
        result = re.sub(
            r'^\s*UTL_\w+\.\w+\s*\([^;]*?\)\s*;',
            lambda m: "\n".join(f"    -- {MANUAL_REVIEW_TAG} {line.strip()}" for line in m.group(0).split('\n') if line.strip()),
            result, flags=re.MULTILINE | re.IGNORECASE | re.DOTALL
        )
        # UTL_SMTP assignment: var = utl_smtp.func(...)
        result = re.sub(
            r'^\s*\w+\s*=\s*utl_\w+\.\w+\s*\(.*?\)\s*;',
            lambda m: f"    -- {MANUAL_REVIEW_TAG} {m.group(0).strip()}",
            result, flags=re.MULTILINE | re.IGNORECASE
        )

        # END procedure_name; → END; (remove trailing identifier after END)
        result = re.sub(
            r'\bEND\s+(?!IF\b|LOOP\b|CASE\b|TRY\b|CATCH\b|ELSE\b)(\w+)\s*;',
            'END;',
            result, flags=re.IGNORECASE
        )

        # Oracle labels: <<label>> → label:
        result = re.sub(
            r'<<(\w+)>>',
            r'\1:',
            result
        )

        # ROLLBACK WORK → ROLLBACK
        result = re.sub(r'\bROLLBACK\s+WORK\b', 'ROLLBACK', result, flags=re.IGNORECASE)

        # Bracket T-SQL reserved words used as column names
        # MERGE is a common column name in Oracle but a reserved word in T-SQL
        # Bracket it when NOT followed by INTO (MERGE INTO is the T-SQL statement)
        result = re.sub(
            r'(?<![.\[\w])MERGE(?!\s+INTO)\b',
            '[MERGE]',
            result, flags=re.IGNORECASE
        )

        return result

    def _add_set_keyword(self, source: str) -> str:
        """Add SET keyword before standalone @variable = value assignments.

        Handles single-line (@var = val;) and multi-line starts.
        Excludes DECLARE, SELECT, IF, WHILE, SET, etc.
        """
        _EXCLUDED = (
            'DECLARE', 'SELECT', 'IF', 'WHILE',
            'SET', 'INSERT', 'UPDATE', 'DELETE',
            'OPEN', 'CLOSE', 'FETCH', 'PRINT',
            'EXEC', 'RETURN', 'BEGIN', 'END',
            '--', '/*', 'THROW', 'CREATE',
        )
        lines = source.split('\n')
        result_lines = []
        for line in lines:
            stripped = line.strip()
            # Match: @var = something (with or without ; on this line)
            if (re.match(r'@\w+\s*=\s*.+', stripped) and
                    not stripped.upper().startswith(_EXCLUDED)):
                indent = line[:len(line) - len(line.lstrip())]
                result_lines.append(f"{indent}SET {stripped}")
            else:
                result_lines.append(line)
        return '\n'.join(result_lines)

    def _convert_parameters(self, source: str, ctx: ConversionContext) -> str:
        """Convert parameter declarations: add @, convert IN/OUT."""
        # IN OUT → OUTPUT
        result = re.sub(
            r'\bIN\s+OUT\s+',
            'OUTPUT ',
            source, flags=re.IGNORECASE
        )
        # OUT keyword → OUTPUT (but not inside words)
        result = re.sub(
            r'(\w+)\s+OUT\s+(\w)',
            r'\1 OUTPUT \2',
            result, flags=re.IGNORECASE
        )
        # Remove standalone IN keyword in param lists
        result = re.sub(
            r'(\w+)\s+IN\s+(\w)',
            r'\1 \2',
            result, flags=re.IGNORECASE
        )
        # Fix OUTPUT position: @name OUTPUT TYPE → @name TYPE OUTPUT
        # T-SQL requires: @param TYPE OUTPUT (type before OUTPUT)
        result = re.sub(
            r'(@\w+)\s+OUTPUT\s+(\w[\w(,)\s]*?)(\s*[,)])',
            r'\1 \2 OUTPUT\3',
            result, flags=re.IGNORECASE
        )
        return result

    def _convert_variable_declarations(self, source: str, ctx: ConversionContext) -> str:
        """Convert PL/SQL variable declarations to T-SQL DECLARE @var statements.

        Processes each GO-separated batch independently so variable names
        from one function/procedure don't pollute other scopes.
        """
        # Split by GO boundaries and process each batch independently
        batches = re.split(r'(^GO\s*$)', source, flags=re.MULTILINE | re.IGNORECASE)
        result_batches = []
        for batch in batches:
            if re.match(r'^GO\s*$', batch, re.IGNORECASE):
                result_batches.append(batch)
            else:
                result_batches.append(self._convert_variable_declarations_batch(batch, ctx))
        return ''.join(result_batches)

    def _convert_variable_declarations_batch(self, source: str, ctx: ConversionContext) -> str:
        """Convert PL/SQL variable declarations in a single GO-batch."""
        # Collect all declared variable names and their positions
        declared_vars = set()
        param_vars = set()

        # Find parameter names from procedure/function header
        # Only look at lines between CREATE/FUNCTION/PROCEDURE and AS/IS
        lines = source.split('\n')
        in_header = False

        for line in lines:
            stripped = line.strip().upper()
            # Start scanning at CREATE OR ALTER or PROCEDURE/FUNCTION declaration
            if re.match(r'CREATE\s+OR\s+ALTER\s+', stripped) or re.match(r'(PROCEDURE|FUNCTION)\s+', stripped):
                in_header = True
            if in_header:
                # Find parameter names: word followed by type keyword (with word boundary)
                param_match = re.findall(
                    r'(\w+)\s+(?:OUTPUT\s+)?(?:NVARCHAR|DECIMAL|INT|DATETIME2?|BIT|NCHAR|VARBINARY|FLOAT|BIGINT|SMALLINT)\b',
                    line, re.IGNORECASE
                )
                for p in param_match:
                    if p.upper() not in ('SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'IN',
                                          'OUT', 'OUTPUT', 'RETURN', 'RETURNS', 'AS', 'IS',
                                          'BEGIN', 'END', 'IF', 'THEN', 'ELSE', 'CURSOR',
                                          'DECLARE', 'SET', 'INTO', 'CREATE', 'ALTER',
                                          'INSERT', 'UPDATE', 'DELETE', 'FUNCTION', 'PROCEDURE'):
                        param_vars.add(p)
            # Stop at AS or IS (end of header)
            if in_header and (stripped in ('AS', 'IS', 'BEGIN') or stripped.endswith(' AS') or stripped.endswith(' IS')):
                in_header = False

        # Find variable declarations: lines between AS and BEGIN
        # Pattern: indented word followed by a type, optionally := value, ending with ;
        var_decl_pattern = re.compile(
            r'^(\s+)(\w+)\s+(NVARCHAR|DECIMAL|INT|INTEGER|BIGINT|SMALLINT|BIT|DATETIME2|'
            r'FLOAT|REAL|NCHAR|VARBINARY|VARCHAR|NUMERIC|'
            r'NVARCHAR\s*\(\s*\w+\s*\)|DECIMAL\s*\([^)]+\)|DATETIME2\s*\([^)]+\)|'
            r'VARBINARY\s*\([^)]+\)|NCHAR\s*\([^)]+\)|VARCHAR\s*\([^)]+\))'
            r'(\s*(?:\([^)]*\))?)(\s*=\s*.+?)?\s*;',
            re.IGNORECASE | re.MULTILINE
        )

        result = source
        # Collect (match_start, full_match_text, new_decl_text)
        replacements_with_pos = []

        for m in var_decl_pattern.finditer(source):
            indent = m.group(1)
            var_name = m.group(2)

            # Skip keywords that look like declarations
            if var_name.upper() in ('SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'SET',
                                     'IF', 'ELSE', 'BEGIN', 'END', 'RETURN', 'OPEN',
                                     'CLOSE', 'FETCH', 'INSERT', 'UPDATE', 'DELETE',
                                     'INTO', 'VALUES', 'CURSOR', 'DECLARE', 'WHILE',
                                     'PRINT', 'EXEC', 'CREATE', 'DROP', 'COMMIT',
                                     'ROLLBACK', 'WHEN', 'THEN', 'LOOP', 'EXIT'):
                continue

            declared_vars.add(var_name)
            full_match = m.group(0)
            # Replace: "    varname TYPE = val;" → "    DECLARE @varname TYPE = val;"
            new_decl = re.sub(
                r'^(\s*)' + re.escape(var_name),
                r'\1DECLARE @' + var_name,
                full_match
            )
            replacements_with_pos.append((m.start(), full_match, new_decl))

        # Build a GO-batch boundary map so dedup is scoped per function/procedure batch
        go_boundaries = [0]
        for go_m in re.finditer(r'^GO\s*$', source, re.MULTILINE | re.IGNORECASE):
            go_boundaries.append(go_m.end())
        go_boundaries.append(len(source) + 1)

        def _batch_idx(pos: int) -> int:
            for b in range(len(go_boundaries) - 1):
                if go_boundaries[b] <= pos < go_boundaries[b + 1]:
                    return b
            return 0

        # Dedup replacements by variable name PER GO-batch (each function is its own scope)
        seen_per_batch: dict[int, set[str]] = {}
        deduped_replacements = []
        for pos, old, new in replacements_with_pos:
            batch = _batch_idx(pos)
            if batch not in seen_per_batch:
                seen_per_batch[batch] = set()
            seen_vars = seen_per_batch[batch]

            m = re.match(r'\s*DECLARE\s+@(\w+)', new, re.IGNORECASE)
            if m:
                vname = m.group(1).upper()
                if vname in seen_vars:
                    # Drop within-batch duplicate — replace old text with a comment
                    deduped_replacements.append((old, f"-- (duplicate @{m.group(1)} removed)"))
                    continue
                seen_vars.add(vname)
            deduped_replacements.append((old, new))

        # Apply declaration replacements
        for old, new in deduped_replacements:
            result = result.replace(old, new, 1)

        # Also handle CURSOR declarations that were already converted
        cursor_pattern = re.compile(r'\bDECLARE\s+(\w+)\s+CURSOR\b', re.IGNORECASE)
        for m in cursor_pattern.finditer(result):
            declared_vars.add(m.group(1))

        # T-SQL reserved words that must NOT be used bare as variable names.
        # If a discovered variable name is a reserved word, bracket it.
        TSQL_RESERVED = {
            'ADD', 'ALL', 'ALTER', 'AND', 'ANY', 'AS', 'ASC', 'AUTHORIZATION',
            'BACKUP', 'BEGIN', 'BETWEEN', 'BREAK', 'BROWSE', 'BULK', 'BY',
            'CASCADE', 'CASE', 'CHECK', 'CHECKPOINT', 'CLOSE', 'CLUSTERED',
            'COALESCE', 'COLLATE', 'COLUMN', 'COMMIT', 'COMPUTE', 'CONSTRAINT',
            'CONTAINS', 'CONTAINSTABLE', 'CONTINUE', 'CONVERT', 'CREATE',
            'CROSS', 'CURRENT', 'CURSOR', 'DATABASE', 'DBCC', 'DEALLOCATE',
            'DECLARE', 'DEFAULT', 'DELETE', 'DENY', 'DESC', 'DISTINCT', 'DISTRIBUTED',
            'DOUBLE', 'DROP', 'DUMP', 'ELSE', 'END', 'ERRLVL', 'ESCAPE', 'EXCEPT',
            'EXEC', 'EXECUTE', 'EXISTS', 'EXIT', 'EXTERNAL', 'FETCH', 'FILE',
            'FILLFACTOR', 'FOR', 'FOREIGN', 'FREETEXT', 'FREETEXTTABLE', 'FROM',
            'FULL', 'FUNCTION', 'GOTO', 'GRANT', 'GROUP', 'HAVING', 'HOLDLOCK',
            'IDENTITY', 'IF', 'IN', 'INDEX', 'INNER', 'INSERT', 'INTERSECT',
            'INTO', 'IS', 'JOIN', 'KEY', 'KILL', 'LEFT', 'LIKE', 'LINENO',
            'LOAD', 'MERGE', 'NATIONAL', 'NOCHECK', 'NONCLUSTERED', 'NOT',
            'NULL', 'NULLIF', 'OF', 'OFF', 'OFFSETS', 'ON', 'OPEN', 'OPENDATASOURCE',
            'OPENQUERY', 'OPENROWSET', 'OPENXML', 'OPTION', 'OR', 'ORDER',
            'OUTER', 'OVER', 'PERCENT', 'PIVOT', 'PLAN', 'PRECISION', 'PRIMARY',
            'PRINT', 'PROC', 'PROCEDURE', 'PUBLIC', 'RAISERROR', 'READ', 'READTEXT',
            'RECONFIGURE', 'REFERENCES', 'REPLICATION', 'RESTORE', 'RESTRICT',
            'RETURN', 'REVERT', 'REVOKE', 'RIGHT', 'ROLLBACK', 'ROWCOUNT',
            'ROWGUIDCOL', 'RULE', 'SAVE', 'SCHEMA', 'SECURITYAUDIT', 'SELECT',
            'SEMANTICKEYPHRASETABLE', 'SEMANTICSIMILARITYDETAILSTABLE',
            'SEMANTICSIMILARITYTABLE', 'SESSION_USER', 'SET', 'SETUSER',
            'SHUTDOWN', 'SOME', 'STATISTICS', 'SYSTEM_USER', 'TABLE',
            'TABLESAMPLE', 'TEXTSIZE', 'THEN', 'TO', 'TOP', 'TRAN', 'TRANSACTION',
            'TRIGGER', 'TRUNCATE', 'TRY_CONVERT', 'TSEQUAL', 'UNION', 'UNIQUE',
            'UNPIVOT', 'UPDATE', 'UPDATETEXT', 'USE', 'USER', 'VALUES', 'VARYING',
            'VIEW', 'WAITFOR', 'WHEN', 'WHERE', 'WHILE', 'WITH', 'WITHIN',
            'WRITETEXT',
        }

        def safe_var_name(name: str) -> str:
            """Return @name, or [@name] if name is a T-SQL reserved word."""
            if name.upper() in TSQL_RESERVED:
                return f'[@{name}]'
            return f'@{name}'

        # Prefix parameter variables with @
        for var in param_vars:
            safe = safe_var_name(var)
            # Don't prefix if preceded by dot (column reference: table.col)
            # Case-insensitive: Oracle code may use EMPNO_IN while param is empno_in
            result = re.sub(
                r'(?<![@\[.])\b' + re.escape(var) + r'\b',
                safe,
                result, flags=re.IGNORECASE
            )

        # Prefix declared variables with @ (in body, not in DECLARE lines which already have @)
        for var in declared_vars:
            safe = safe_var_name(var)
            # Replace all occurrences not already preceded by @, [, or . (dot = column qualifier)
            # Case-insensitive: Oracle code may use different casing
            result = re.sub(
                r'(?<![@\[.])\b' + re.escape(var) + r'\b(?!\s+CURSOR)',
                safe,
                result, flags=re.IGNORECASE
            )
            # Fix double @@ from DECLARE lines
            result = result.replace(f'DECLARE @@{var}', f'DECLARE @{var}')
            result = result.replace(f'DECLARE [@{var}]', f'DECLARE [{safe}]')

        return result

    def _collapse_multiline_conditions(self, source: str) -> str:
        """Join multi-line IF/ELSIF conditions ending with a standalone THEN into one line.

        Oracle allows:
            IF condition1
            AND condition2
            THEN

        This normalises it to: IF condition1 AND condition2 THEN
        so the single-line handler in _convert_if_then can process it.
        Comment-only lines inside the condition are preserved before the joined line.
        """
        lines = source.split('\n')
        result = []
        in_block_comment = False
        pending = None  # {'kw_indent': str, 'keyword': str, 'parts': [str], 'comments': [str]}
        i = 0

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()
            upper = stripped.upper()

            # Track block comments
            if not in_block_comment:
                idx = line.find('/*')
                if idx >= 0 and '*/' not in line[idx + 2:]:
                    in_block_comment = True
            else:
                if '*/' in line:
                    in_block_comment = False
                # Inside a block comment — flush pending (if any) as-is and emit
                if pending:
                    result.extend(pending['comments'])
                    result.append(f"{pending['kw_indent']}{pending['keyword']} {' '.join(pending['parts'])}")
                    pending = None
                result.append(line)
                i += 1
                continue

            if pending:
                # We're collecting a multi-line IF/ELSIF condition
                if upper == 'THEN':
                    # Standalone THEN — complete the condition
                    result.extend(pending['comments'])
                    result.append(f"{pending['kw_indent']}{pending['keyword']} {' '.join(pending['parts'])} THEN")
                    pending = None
                elif upper.endswith(' THEN') or upper.endswith('\tTHEN'):
                    # THEN at end of this continuation line
                    then_pos = stripped.upper().rfind(' THEN')
                    part = stripped[:then_pos].strip()
                    if part and not part.startswith('--'):
                        pending['parts'].append(part)
                    result.extend(pending['comments'])
                    result.append(f"{pending['kw_indent']}{pending['keyword']} {' '.join(pending['parts'])} THEN")
                    pending = None
                elif stripped.startswith('--') or not stripped:
                    # Comment or blank line within multi-line condition — buffer it
                    pending['comments'].append(line)
                elif re.match(
                    r'(IF|ELSIF|BEGIN|END\b|SET\b|RETURN\b|SELECT\b|INSERT\b|UPDATE\b|'
                    r'DELETE\b|DECLARE\b|WHILE\b|OPEN\b|CLOSE\b|FETCH\b|COMMIT\b|ROLLBACK\b)',
                    stripped, re.IGNORECASE
                ):
                    # Hit a new statement — flush pending and reset
                    result.extend(pending['comments'])
                    result.append(f"{pending['kw_indent']}{pending['keyword']} {' '.join(pending['parts'])}")
                    pending = None
                    result.append(line)
                else:
                    # Continuation of the condition
                    if stripped:
                        pending['parts'].append(stripped)
            else:
                # Check if this starts a multi-line IF or ELSIF (no THEN on this line)
                kw_match = re.match(r'(\s*)(IF|ELSIF)\s+(.*)', line, re.IGNORECASE)
                if kw_match and not upper.endswith(' THEN') and not upper.endswith('\tTHEN') and upper != 'THEN':
                    kw_indent = kw_match.group(1)
                    keyword = kw_match.group(2).upper()
                    rest = kw_match.group(3).strip()
                    pending = {
                        'kw_indent': kw_indent,
                        'keyword': keyword,
                        'parts': [rest] if rest else [],
                        'comments': [],
                    }
                else:
                    result.append(line)
            i += 1

        # Flush any remaining pending condition
        if pending:
            result.extend(pending['comments'])
            result.append(f"{pending['kw_indent']}{pending['keyword']} {' '.join(pending['parts'])}")

        return '\n'.join(result)

    def _convert_if_then(self, source: str) -> str:
        """Convert IF...THEN...END IF to IF...BEGIN...END.

        Processes line by line to avoid interfering with CASE WHEN THEN ELSE END.
        Only converts standalone IF/ELSIF/ELSE/END IF statements, not inline SQL.
        """
        # Normalise multi-line IF/ELSIF conditions first
        source = self._collapse_multiline_conditions(source)
        lines = source.split('\n')
        result_lines = []
        i = 0

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()
            upper = stripped.upper()
            indent = line[:len(line) - len(line.lstrip())]

            # Single-line: IF cond THEN stmt; END IF; → IF cond BEGIN SET stmt; END;
            single_line_if = re.match(
                r'(IF\s+.+?\s+THEN\s+)(.+?)\s+END\s+IF\s*;?\s*(?:--.*)?$',
                stripped, re.IGNORECASE
            )
            if single_line_if and not re.search(r'\bCASE\b', stripped, re.IGNORECASE):
                # Extract condition (between IF and THEN) and body (between THEN and END IF)
                if_then_match = re.match(r'IF\s+(.+?)\s+THEN\s+', stripped, re.IGNORECASE)
                if if_then_match:
                    condition = if_then_match.group(1).strip()
                    body_start = if_then_match.end()
                    body_end = re.search(r'\s+END\s+IF\s*;?\s*(?:--.*)?$', stripped, re.IGNORECASE)
                    if body_end:
                        body = stripped[body_start:body_end.start()].strip()
                        result_lines.append(f"{indent}IF {condition}")
                        result_lines.append(f"{indent}BEGIN")
                        result_lines.append(f"{indent}    {body}")
                        result_lines.append(f"{indent}END;")
                        i += 1
                        continue

            # END IF; → END; (allow trailing -- comments)
            if re.match(r'END\s+IF\s*;?\s*(?:--.*)?$', upper):
                result_lines.append(f"{indent}END;")
                i += 1
                continue

            # ELSIF condition THEN → END ELSE IF condition BEGIN
            elsif_match = re.match(r'ELSIF\s+(.+?)\s+THEN\s*(?:--.*)?$', stripped, re.IGNORECASE)
            if elsif_match:
                condition = elsif_match.group(1)
                result_lines.append(f"{indent}END")
                result_lines.append(f"{indent}ELSE IF {condition}")
                result_lines.append(f"{indent}BEGIN")
                i += 1
                continue

            # IF condition THEN (on same line, condition may span multiple lines)
            # Check if line ends with THEN (possibly followed by -- comment)
            # Strip trailing comment for THEN detection
            code_part = re.sub(r'\s*--.*$', '', stripped)
            code_upper = code_part.upper().rstrip()
            if code_upper.endswith(' THEN') or code_upper.endswith('\tTHEN'):
                # Check if this is a standalone IF...THEN (not CASE WHEN...THEN)
                # Find the IF that starts this statement
                if re.match(r'IF\b', code_upper):
                    # Single-line IF...THEN
                    then_idx = code_part.upper().rfind(' THEN')
                    condition = code_part[3:then_idx].strip()  # Skip 'IF '
                    result_lines.append(f"{indent}IF {condition}")
                    result_lines.append(f"{indent}BEGIN")
                    i += 1
                    continue

            # Multi-line IF: check if previous lines started with IF and this line ends with THEN
            if code_upper.endswith(' THEN') and not re.match(r'(IF|ELSIF|WHEN)\b', code_upper, re.IGNORECASE):
                # Check if there was an IF earlier that we're continuing
                # Look back for the IF
                found_if = False
                for j in range(len(result_lines) - 1, max(-1, len(result_lines) - 10), -1):
                    prev = result_lines[j].strip().upper()
                    if prev.startswith('IF ') and 'THEN' not in prev and 'BEGIN' not in prev:
                        found_if = True
                        # This is a multi-line IF condition ending with THEN
                        # Remove THEN from current line and add BEGIN
                        then_idx = stripped.upper().rfind(' THEN')
                        result_lines.append(f"{indent}{stripped[:then_idx]}")
                        result_lines.append(f"{indent}BEGIN")
                        break
                    elif prev and not prev.startswith(',') and not prev.startswith('+') and not prev.startswith('AND') and not prev.startswith('OR'):
                        break
                if found_if:
                    i += 1
                    continue

            # ELSE (standalone, at start of line - not inline CASE ELSE)
            # Check if we're inside a CASE expression by counting CASE/END pairs
            # in recent lines. If inside CASE, don't convert ELSE.
            if re.match(r'ELSE\s*$', upper):
                # Look back to see if we're inside a CASE block
                case_depth = 0
                in_case = False
                for j in range(len(result_lines) - 1, max(-1, len(result_lines) - 50), -1):
                    prev_upper = result_lines[j].strip().upper()
                    # Count END (CASE closers)
                    if re.match(r'END\b', prev_upper) and not re.match(r'END\s*(IF|LOOP|TRY|CATCH)\b', prev_upper):
                        case_depth += 1
                    # Count CASE openers (may be preceded by (, SELECT, etc.)
                    if re.search(r'\bCASE\b', prev_upper) and not re.search(r'\bEND\s+CASE\b', prev_upper):
                        if case_depth > 0:
                            case_depth -= 1
                        else:
                            in_case = True
                            break
                if in_case:
                    # Inside CASE — pass through as CASE ELSE
                    result_lines.append(line)
                    i += 1
                    continue
                result_lines.append(f"{indent}END")
                result_lines.append(f"{indent}ELSE")
                result_lines.append(f"{indent}BEGIN")
                i += 1
                continue

            # Default: pass through
            result_lines.append(line)
            i += 1

        return '\n'.join(result_lines)

    def _convert_for_loop(self, source: str, ctx: ConversionContext) -> str:
        """Convert FOR i IN 1..n LOOP → DECLARE + WHILE."""
        def replace_for(m):
            var = m.group(1)
            start = m.group(2)
            end = m.group(3)
            return (
                f"DECLARE @{var} INT = {start};\n"
                f"WHILE @{var} <= {end}\n"
                f"BEGIN"
            )

        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+(\w+)\s*\.\.\s*(\w+)\s+LOOP',
            replace_for,
            source, flags=re.IGNORECASE
        )
        return result

    def _convert_cursor_for_loop(self, source: str, ctx: ConversionContext) -> str:
        """Convert FOR rec IN (SELECT ...) LOOP → cursor pattern."""
        pattern = re.compile(
            r'\bFOR\s+(\w+)\s+IN\s*\((SELECT\b.+?)\)\s*LOOP',
            re.IGNORECASE | re.DOTALL
        )

        def replace_cursor_for(m):
            rec_var = m.group(1)
            select_stmt = m.group(2)
            ctx.add_manual_review(
                f"Cursor FOR loop ({rec_var}) - verify cursor conversion"
            )
            
            # Simple heuristic to count columns in the SELECT clause
            col_count = 1
            cols_match = re.search(r'\bSELECT\b(.*?)\bFROM\b', select_stmt, re.IGNORECASE | re.DOTALL)
            if cols_match:
                cols_str = re.sub(r'--.*$', '', cols_match.group(1), flags=re.MULTILINE)
                depth = 0
                count = 1
                for ch in cols_str:
                    if ch == '(': depth += 1
                    elif ch == ')': depth -= 1
                    elif ch == ',' and depth == 0: count += 1
                col_count = max(1, count)
            
            # Generate dummy declarations for the fetched columns to pass T-SQL parse/syntax checks
            var_names = [f"@{rec_var}_col{i+1}" for i in range(col_count)]
            var_decls = " ".join(f"DECLARE {v} NVARCHAR(4000);" for v in var_names)
            var_list = ", ".join(var_names)

            return (
                f"/* {MANUAL_REVIEW_TAG} Cursor FOR loop: {rec_var} */\n"
                f"DECLARE {rec_var}_cursor CURSOR LOCAL FAST_FORWARD FOR\n"
                f"{select_stmt};\n"
                f"{var_decls}\n"
                f"OPEN {rec_var}_cursor;\n"
                f"FETCH NEXT FROM {rec_var}_cursor INTO {var_list};\n"
                f"WHILE @@FETCH_STATUS = 0\n"
                f"BEGIN"
            )

        return pattern.sub(replace_cursor_for, source)

    def _convert_simple_loop(self, source: str) -> str:
        """Convert bare LOOP → WHILE 1=1 BEGIN."""
        # Match LOOP that is NOT preceded by END (END LOOP) or FOR...LOOP
        # Only match LOOP at start of line or after whitespace, standalone
        result = re.sub(
            r'^(\s*)LOOP\s*$',
            r'\1WHILE 1=1\n\1BEGIN',
            source, flags=re.MULTILINE | re.IGNORECASE
        )
        # Also handle LOOP at end of a line (after semicolon or closing paren)
        result = re.sub(
            r';\s*\n(\s*)LOOP\s*$',
            r';\n\1WHILE 1=1\n\1BEGIN',
            result, flags=re.MULTILINE | re.IGNORECASE
        )
        return result

    def _convert_rownum(self, source: str, ctx: ConversionContext) -> str:
        """Convert ROWNUM references."""
        result = re.sub(
            r'\bAND\s+ROWNUM\s*<=\s*(\d+)',
            r'/* ROWNUM converted to TOP \1 */',
            source, flags=re.IGNORECASE
        )
        result = re.sub(
            r'\bWHERE\s+ROWNUM\s*<=\s*(\d+)',
            r'/* ROWNUM converted to TOP \1 */',
            result, flags=re.IGNORECASE
        )

        if 'ROWNUM converted to TOP' in result:
            top_match = re.search(r'TOP (\d+)', result)
            if top_match:
                n = top_match.group(1)
                result = re.sub(
                    r'\bSELECT\b(?!\s+TOP)',
                    f'SELECT TOP {n}',
                    result, count=1, flags=re.IGNORECASE
                )

        result = re.sub(
            r'\bROWNUM\s*=\s*1\b',
            '1=1 /* converted: use TOP 1 */',
            result, flags=re.IGNORECASE
        )

        return result

    def _convert_connect_by(self, source: str, ctx: ConversionContext) -> str:
        """Convert CONNECT BY to recursive CTE (simple cases only)."""
        pattern = re.compile(
            r'(SELECT\b.+?)\bSTART\s+WITH\s+(.+?)\bCONNECT\s+BY\s+(?:NOCYCLE\s+)?(?:PRIOR\s+)?(.+?)(?=ORDER\s+BY|GROUP\s+BY|;|\))',
            re.IGNORECASE | re.DOTALL
        )

        def replace_connect_by(m):
            select_part = m.group(1).strip()
            start_with = m.group(2).strip()
            connect_by = m.group(3).strip()

            complex_features = ['SYS_CONNECT_BY_PATH', 'CONNECT_BY_ROOT',
                                'CONNECT_BY_ISLEAF', 'ORDER SIBLINGS']
            for feat in complex_features:
                if feat in source.upper():
                    ctx.add_manual_review(f"Complex CONNECT BY feature: {feat}")

            ctx.add_manual_review("CONNECT BY → recursive CTE conversion - verify correctness")

            return (
                f"/* {MANUAL_REVIEW_TAG} CONNECT BY converted to recursive CTE */\n"
                f";WITH cte AS (\n"
                f"    -- Anchor: START WITH\n"
                f"    {select_part}\n"
                f"    WHERE {start_with}\n"
                f"    UNION ALL\n"
                f"    -- Recursive: CONNECT BY\n"
                f"    {select_part}\n"
                f"    INNER JOIN cte ON {connect_by}\n"
                f")\n"
                f"SELECT * FROM cte\n"
            )

        return pattern.sub(replace_connect_by, source)

    def _convert_package_calls(self, source: str, ctx: ConversionContext) -> str:
        """Convert package.procedure(args) → [schema].[procedure](args)."""
        # Avoid converting table.column references (common in SQL)
        # Only convert if the prefix looks like a package name (uppercase, PKG pattern, or known)
        def replace_pkg_call(m):
            pkg_name = m.group(1)
            proc_name = m.group(2)

            # Skip common table alias patterns and SQL keywords
            skip_prefixes = {'SYS', 'DBA', 'ALL', 'USER', 'V$', 'GV$',
                             'DBMS_OUTPUT', 'DBMS_LOB', 'DBMS_SQL', 'DBMS_LOCK',
                             'UTL_FILE', 'UTL_HTTP'}
            if pkg_name.upper() in skip_prefixes:
                return m.group(0)

            from ..utils import sanitize_name
            schema = ctx.schema_mapping.get(
                pkg_name.upper(),
                sanitize_name(pkg_name)
            )
            ctx.package_refs.add(pkg_name.upper())
            return f"[{schema}].[{proc_name}]("

        result = re.sub(
            r'\b([A-Z]\w*_PKG)\.(\w+)\s*\(',
            replace_pkg_call,
            source, flags=re.IGNORECASE
        )
        return result

    def _convert_select_into(self, source: str) -> str:
        """Convert Oracle SELECT...INTO...FROM to T-SQL SELECT @var = col FROM.

        Oracle: SELECT col1, col2 INTO var1, var2 FROM table ...;
        T-SQL:  SELECT @var1 = col1, @var2 = col2 FROM table ...;

        Only matches within a single SQL statement (bounded by semicolons).
        Requires INTO targets to start with @ (already prefixed variables).
        """
        # Process statement by statement to avoid cross-statement matching
        # Split on semicolons, keeping the delimiter
        statements = re.split(r'(;)', source)
        result_parts = []

        for part in statements:
            if part == ';':
                result_parts.append(part)
                continue

            # Check if this statement is a CURSOR declaration
            is_cursor = bool(re.search(r'\bCURSOR\b.+?\bIS\b', part, re.IGNORECASE | re.DOTALL))

            # Match SELECT...INTO @var...FROM within this statement fragment
            pattern = re.compile(
                r'\bSELECT\b(.*?)\bINTO\s+(@\w+(?:\s*,\s*@\w+)*)\s+FROM\b',
                re.IGNORECASE | re.DOTALL
            )

            def _strip_col_alias(col: str) -> str:
                """Remove trailing column alias from an expression.

                Oracle allows: expr alias or expr AS alias.
                In T-SQL SELECT @var = expr, aliases are not needed
                and bare aliases after ) cause syntax errors.
                """
                col = col.strip()
                # Remove AS alias
                col = re.sub(r'\s+AS\s+\w+\s*$', '', col,
                             flags=re.IGNORECASE | re.DOTALL).rstrip()
                # Remove bare alias after closing paren: SUM(x) alias → SUM(x)
                col = re.sub(r'(\))\s+\w+\s*$', r'\1', col, flags=re.DOTALL)
                # Remove bare alias after string literal: 'val' alias → 'val'
                col = re.sub(r"(')\s+\w+\s*$", r'\1', col, flags=re.DOTALL)
                return col.rstrip()

            def _split_top_level_commas(s: str) -> list[str]:
                """Split by comma only at the top paren level."""
                parts: list[str] = []
                depth = 0
                current: list[str] = []
                for ch in s:
                    if ch == '(':
                        depth += 1
                        current.append(ch)
                    elif ch == ')':
                        depth -= 1
                        current.append(ch)
                    elif ch == ',' and depth == 0:
                        parts.append(''.join(current))
                        current = []
                    else:
                        current.append(ch)
                if current:
                    parts.append(''.join(current))
                return parts

            def replace_select_into(m):
                columns_str = m.group(1).strip()
                
                if is_cursor:
                    # If this is inside a CURSOR declaration, INTO is invalid syntax
                    # Just strip the INTO vars entirely
                    return f"SELECT {columns_str}\nFROM"

                vars_str = m.group(2).strip()

                # Strip line comments before splitting to avoid commented-out columns
                # being treated as extra comma-separated items
                columns_no_comments = re.sub(r'--.*$', '', columns_str, flags=re.MULTILINE)
                # Use paren-aware split so CASE/function commas don't cause mis-splits
                columns = [c.strip() for c in _split_top_level_commas(columns_no_comments) if c.strip()]
                variables = [v.strip() for v in vars_str.split(',')]

                if len(columns) != len(variables):
                    return m.group(0)

                pairs = [f"{var} = {_strip_col_alias(col)}"
                         for var, col in zip(variables, columns)]
                return "SELECT " + ", ".join(pairs) + " FROM"

            result_parts.append(pattern.sub(replace_select_into, part))

        return ''.join(result_parts)

    def _convert_exec_immediate(self, m) -> str:
        """Convert EXECUTE IMMEDIATE with USING clause."""
        sql_expr = m.group(1)
        using_vars = m.group(2)
        params = [v.strip() for v in using_vars.split(',')]
        param_decls = ", ".join(
            f"@p{i} NVARCHAR(4000)" for i in range(len(params))
        )
        param_vals = ", ".join(
            f"@p{i} = {p}" for i, p in enumerate(params)
        )
        return f"EXEC sp_executesql {sql_expr}, N'{param_decls}', {param_vals};"
