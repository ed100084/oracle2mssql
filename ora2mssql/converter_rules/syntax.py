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

        # Fix: @colname in INSERT column list → colname (column names must not have @)
        # Variable substitution may have incorrectly prefixed column names that share a name with a param/var.
        result = re.sub(
            r'(INSERT\s+INTO\s+\w+\s*\()([^;]*?)(\)\s*\n?\s*VALUES)',
            lambda m: m.group(1) + re.sub(r'@(\w+)', r'\1', m.group(2)) + m.group(3),
            result, flags=re.IGNORECASE | re.DOTALL
        )

        # Standalone assignment: @var = value; → SET @var = value;
        result = self._add_set_keyword(result)

        # Strip /*INTO var1, var2*/ block comments — Oracle developers comment out
        # the INTO clause to convert a SELECT INTO statement into a cursor query.
        # These become unclosed block comments after SELECT INTO conversion runs.
        result = re.sub(r'/\*\s*INTO\b[\s\S]*?\*/', '', result, flags=re.IGNORECASE)

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
        # Pattern: ",\n  tablename alias\n  WHERE/CROSS JOIN" → "CROSS JOIN tablename alias\n  ..."
        # Apply twice to handle 3+ comma-joined tables (ta, tb, tc → CROSS JOIN tb CROSS JOIN tc)
        _comma_join_pat = re.compile(
            r',\s*\n(\s*)(\w+)\s+(\w+)\s*\n(\s*(?:WHERE\b|CROSS\s+JOIN\b))',
            re.IGNORECASE
        )
        result = _comma_join_pat.sub(r'\nCROSS JOIN \2 \3\n\4', result)
        result = _comma_join_pat.sub(r'\nCROSS JOIN \2 \3\n\4', result)

        # Oracle inline derived table: FROM (subquery)\n WHERE outer_filter
        # T-SQL requires an alias. Only add when the WHERE block is followed by
        # UNION ALL (non-last UNION member) or ") alias" (last member closing the outer subquery).
        _union_derived_ctr = [0]
        def _add_union_derived_alias(m):
            # Don't add alias if ) closes a scalar subquery in an UPDATE SET clause.
            # Check the line immediately before the matched ) for a SET col = ( pattern.
            before = result[:m.start()]
            last_newline = before.rfind('\n')
            prev_line = before[last_newline + 1:] if last_newline >= 0 else before
            if re.search(r'\bSET\s+\w+\s*=\s*\(', prev_line, re.IGNORECASE):
                return m.group(0)  # No change
            _union_derived_ctr[0] += 1
            return f") AS __ud{_union_derived_ctr[0]}\n{m.group(1)}WHERE"
        # Use [^;]* to prevent crossing statement boundaries (avoid matching across procedures).
        # The ") alias" can appear mid-line (e.g. "AND ... ) ta"), so don't require \n before it.
        result = re.sub(
            r'\)\s*\n(\s*)WHERE\b(?=[^;]*(?:\n\s*UNION\s+ALL|\)\s*[A-Za-z]))',
            _add_union_derived_alias,
            result, flags=re.IGNORECASE | re.DOTALL
        )

        # Fix B: FROM (SELECT...) without alias at end of statement → add AS __dcN alias.
        # T-SQL requires aliases on all derived tables. Uses balanced-paren counting to
        # handle arbitrary nesting depth (e.g. FORMAT(ISNULL(...))).
        result = self._fix_derived_table_aliases(result)

        # Fix C: outer FROM subquery where inner WHERE closes on ) and outer WHERE follows.
        # Pattern: line starting with WHERE ... ) \n outer WHERE
        # This catches e.g. WHERE emp_no = @pempno)\nWHERE FORMAT(...)
        _od_ctr = [0]
        def _add_outer_subq_alias(m):
            _od_ctr[0] += 1
            return f"{m.group(1)}) AS __od{_od_ctr[0]}\n{m.group(2)}WHERE"
        result = re.sub(
            r'(?m)^([ \t]+WHERE\b[^\n]*)\)\s*\n(\s*)WHERE\b',
            _add_outer_subq_alias,
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

        # Bug 8: offrec_ovrtrans — CURSOR subquery missing alias before ORDER BY
        # Pattern: )\n  order by signman; inside a DECLARE CURSOR FOR clause
        result = re.sub(
            r'\)\s*\n(\s*order\s+by\s+signman\s*;)',
            r') AS __derived\n\1',
            result, flags=re.IGNORECASE
        )
        # Bug 8: rownum in RANK() OVER ORDER BY → remove rownum (not valid in T-SQL)
        result = re.sub(
            r'(order\s+by\s+\w+(?:\s+(?:asc|desc))?)\s*,\s*rownum\b',
            r'\1',
            result, flags=re.IGNORECASE
        )

        # offrec_ovrtrans cursor3 CTE: nested derived tables missing aliases
        # Fix 1: ) on its own line immediately before GROUP BY (innermost derived table).
        # Require ) to be at start of line to avoid matching function-call parens in WHERE clauses.
        result = re.sub(
            r'^(\s*)\)\s*\n(\s*)(group\s+by\b)',
            r'\1) AS __grp_d\n\2\3',
            result, flags=re.IGNORECASE | re.MULTILINE
        )
        # Fix 2: ) where rnk = 1 → ) AS __outer_d where rnk = 1 (outer derived table)
        result = re.sub(
            r'\)\s*(where\s+rnk\s*=\s*1)',
            r') AS __outer_d \1',
            result, flags=re.IGNORECASE
        )
        # Fix 3: ) before ) where (middle derived table, applied after fix 2)
        result = re.sub(
            r'\)\s*\n(\s*\)\s+AS\s+__outer_d\b)',
            r') AS __mid_d\n\1',
            result, flags=re.IGNORECASE
        )

        # Fix: UPDATE SET col IS NULL → UPDATE SET col = NULL
        # (= NULL → IS NULL conversion incorrectly applied to SET assignments)
        result = re.sub(
            r'\bSET\s+(\w+)\s+IS\s+NULL\b',
            r'SET \1 = NULL',
            result, flags=re.IGNORECASE
        )

        # Fix: hrpuser.MAILQUEUE.insertMailQueue(args) standalone call → EXEC
        result = re.sub(
            r'^(\s*)hrpuser\.MAILQUEUE\.insertMailQueue\s*\(([^;]*)\)\s*;',
            lambda m: f"{m.group(1)}EXEC [hrpuser].[insertMailQueue] {m.group(2).strip()};",
            result, flags=re.IGNORECASE | re.MULTILINE
        )

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
        # Use a counter for unique DECLARE names to avoid redeclaration errors in
        # functions where multiple GOTO-removed blocks may appear.
        _goto_noop_counter = [0]
        def _make_goto_noop(m):
            _goto_noop_counter[0] += 1
            return (
                f'BEGIN\n      /* ORA2MSSQL: GOTO removed */\n'
                f'      DECLARE @__goto{_goto_noop_counter[0]} INT = 0;  -- no-op\n'
                f'    END;\n'
            )
        result = re.sub(
            r'\bBEGIN\s*/\*\s*\[ORA2MSSQL:MANUAL_REVIEW\] Function cannot contain GOTO.*?\*/\s*END\b;?(?:$|\s)',
            _make_goto_noop,
            result, flags=re.IGNORECASE
        )

        # NULL statement → valid T-SQL no-op (comment-only body is invalid in IF blocks)
        result = re.sub(r'^\s*NULL\s*;\s*$', '    PRINT \'\';  -- NULL (no-op)', result, flags=re.MULTILINE | re.IGNORECASE)

        # SSMA converts Oracle NULL; statement to DECLARE @db_null_statement int.
        # This is also not valid as an IF-branch body. Replace with a no-op.
        result = re.sub(
            r'\bDECLARE\s+@db_null_statement\s+\w+\s*;?',
            "PRINT '';  -- NULL (no-op)",
            result, flags=re.IGNORECASE
        )

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
        # Comment each line individually so continuation lines are also commented out
        result = re.sub(
            r'^\s*utl_\w+\.\w+\s*\(.*?\)\s*;',
            lambda m: "\n".join(f"    -- {MANUAL_REVIEW_TAG} {line.strip()}" for line in m.group(0).split('\n') if line.strip()),
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

        # T-SQL rejects BEGIN...END blocks that contain only whitespace or line comments.
        # Add PRINT no-op to ensure at least one executable statement in the block.
        # Must run AFTER UTL_* comment-out so comment-only IF bodies are detected.
        result = re.sub(
            r'(?m)^([ \t]*)(BEGIN)\s*\n((?:[ \t]*(?:--[^\n]*)?\n)*)([ \t]*)(END\b(?!\s+TRY\b|\s+CATCH\b))',
            r"\1\2\n\3\4PRINT '';  -- no-op\n\4\5",
            result, flags=re.IGNORECASE
        )

        # END procedure_name; → END; (remove trailing identifier after END)
        result = re.sub(
            r'\bEND\s+(?!IF\b|LOOP\b|CASE\b|TRY\b|CATCH\b|ELSE\b)(\w+)\s*;',
            'END;',
            result, flags=re.IGNORECASE
        )

        # Oracle labels: <<label>> → label:  (deduplicate within each GO batch)
        # Labels in different SPs don't conflict, so reset counter at each GO boundary.
        go_sep = re.compile(r'^GO\s*$', re.MULTILINE)
        batches = go_sep.split(result)
        processed_batches = []
        for batch in batches:
            _lbl_counts: dict[str, int] = {}
            def _unique_label(m, _c=_lbl_counts):
                name = m.group(1)
                count = _c.get(name, 0) + 1
                _c[name] = count
                if count == 1:
                    return f"{name}:"
                return f"{name}_{count}:"
            processed_batches.append(re.sub(r'<<(\w+)>>', _unique_label, batch))
        result = 'GO\n'.join(processed_batches)

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

        # ---------------------------------------------------------
        # Bug 3B: BIT variable used as bare IF condition (error 4145)
        # Oracle BOOLEAN maps to T-SQL BIT, but T-SQL requires explicit comparison.
        # IF @var BEGIN → IF @var <> 0 BEGIN
        # ---------------------------------------------------------
        result = re.sub(
            r'\bIF\s+(@\w+)\s*\n(\s*)BEGIN\b',
            r'IF \1 <> 0\n\2BEGIN',
            result, flags=re.IGNORECASE
        )
        result = re.sub(
            r'\bIF\s+\((@\w+)\)\s*\n(\s*)BEGIN\b',
            r'IF (\1 <> 0)\n\2BEGIN',
            result, flags=re.IGNORECASE
        )

        # ---------------------------------------------------------
        # Bug 6: Bare [schema].[proc](...) as a statement — needs EXEC prefix.
        # Cross-package calls converted from pkg.proc(...) may lack EXEC.
        # Only applies to standalone statement lines (not SET/SELECT/RETURN/DECLARE context).
        # ---------------------------------------------------------
        def _add_exec_prefix(m):
            indent_str = m.group(1)
            schema_proc = m.group(2)
            args = m.group(3).strip()
            return f"{indent_str}EXEC {schema_proc} {args};"

        # Negative lookbehind: skip if previous line ends with operator (+,-,*,/,=,,),
        # which means [schema].[proc]( is a continuation of an expression, not a standalone call.
        # Use (?:'[^']*'|[^;])* for args to skip over string literals containing ';' so the
        # statement-terminating ';' is not mistakenly matched inside a string literal.
        result = re.sub(
            r'(?<![+\-*/=,(]\n)^(\s*)(?!SET\b|SELECT\b|RETURN\b|DECLARE\b|--|\s*@|\s*/\*)(\[[\w_]+\]\.\[[\w_]+\])\(((?:\'[^\']*\'|[^;])*)\)\s*;',
            _add_exec_prefix,
            result, flags=re.IGNORECASE | re.MULTILINE
        )

        # Fix UpdateSupdtl: EXEC arg 'string' + ERROR_NUMBER() is not valid T-SQL syntax.
        # In T-SQL, EXEC positional args cannot be expressions; pre-declare a variable.
        result = re.sub(
            r"(\n(\s*)EXEC\s+\[[\w_]+\]\.\[[\w_]+\][^\n]*,\s*\n)(\s*)(('(?:[^']|'')*')\s*\+\s*ERROR_NUMBER\s*\(\s*\))\s*;",
            lambda m: (
                f"\n{m.group(2)}DECLARE @__errmsg NVARCHAR(MAX) = {m.group(5)}"
                f" + CAST(ERROR_NUMBER() AS NVARCHAR(10));"
                f"{m.group(1)}{m.group(3)}@__errmsg;"
            ),
            result, flags=re.IGNORECASE
        )

        # ---------------------------------------------------------
        # Bug 1: END; immediately before ELSE → remove semicolon.
        # Occurs when an inner IF-ELSE block closes with END; but an outer ELSE follows.
        # T-SQL requires END (no semicolon) before ELSE.
        # Applied iteratively since nested patterns may need multiple passes.
        # ---------------------------------------------------------
        for _ in range(5):
            result_new = re.sub(
                r'\bEND\s*;\s*(\n[ \t]*(?:--[^\n]*\n[ \t]*)*)(\bELSE\b)',
                r'END\n\1\2',
                result, flags=re.IGNORECASE
            )
            if result_new == result:
                break
            result = result_new

        # Pre-declare expression args in EXEC calls (T-SQL EXEC positional args
        # cannot be expressions like @var + 'str' or 'a' + 'b').
        result = self._fix_exec_expressions(result)

        # Wrap top-level TRY/CATCH in BEGIN...END
        # T-SQL fails to parse procedures where DECLARE statements appear
        # directly before BEGIN TRY without an enclosing BEGIN...END.
        result = self._wrap_top_level_try_catch(result)

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
        last_nonempty_stripped = ''
        for line in lines:
            stripped = line.strip()
            # Match: @var = something (with or without ; on this line)
            # Skip if current line ends with AND/OR (is itself a condition continuation)
            # Skip if previous non-empty line ends with AND/OR (we're inside a multi-line condition)
            curr_ends_cond = bool(re.search(r'\b(AND|OR)\s*$', stripped, re.IGNORECASE))
            prev_ends_cond = bool(re.search(r'\b(AND|OR)\s*$', last_nonempty_stripped, re.IGNORECASE))
            if (re.match(r'@\w+\s*=\s*.+', stripped) and
                    not stripped.upper().startswith(_EXCLUDED) and
                    not curr_ends_cond and
                    not prev_ends_cond):
                indent = line[:len(line) - len(line.lstrip())]
                result_lines.append(f"{indent}SET {stripped}")
            else:
                result_lines.append(line)
            if stripped:
                last_nonempty_stripped = stripped
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
                rest_upper = kw_match.group(3).upper() if kw_match else ''
                if (kw_match and not upper.endswith(' THEN') and not upper.endswith('\tTHEN')
                        and upper != 'THEN' and ' THEN' not in rest_upper):
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

            # ELSE body; (inline single-statement ELSE — Oracle allows "else stmt;" on one line)
            # Distinguish from CASE ELSE by requiring the body to end with ';' (not 'END;').
            else_inline = re.match(r'ELSE\s+(.+;\s*)$', stripped, re.IGNORECASE)
            if else_inline:
                body = else_inline.group(1).strip()
                # Avoid matching CASE ELSE value END; patterns
                body_upper = body.upper().rstrip('; \t')
                if not body_upper.endswith('END'):
                    result_lines.append(f"{indent}END")
                    result_lines.append(f"{indent}ELSE")
                    result_lines.append(f"{indent}BEGIN")
                    result_lines.append(f"{indent}    {body}")
                    i += 1
                    continue

            # ELSE (standalone, at start of line - not inline CASE ELSE)
            # Check if we're inside a CASE expression by counting CASE/END pairs
            # in recent lines. If inside CASE, don't convert ELSE.
            if re.match(r'ELSE\s*(?:--.*)?$', upper):
                # If the previous significant line is END;/END TRY/END CATCH, we are
                # definitely at procedure statement level (not inside a SQL CASE expression).
                # Skip the CASE heuristic and always inject END ELSE BEGIN.
                prev_significant = None
                for j in range(len(result_lines) - 1, max(-1, len(result_lines) - 10), -1):
                    s = result_lines[j].strip()
                    if s and not s.startswith('--') and not s.startswith('/*'):
                        prev_significant = s.upper()
                        break
                force_not_in_case = bool(
                    prev_significant and re.match(r'END\s*(TRY|CATCH|;|$)', prev_significant)
                )

                in_case = False
                if not force_not_in_case:
                    # Look back to see if we're inside a CASE block.
                    # Count inline END occurrences to track balanced CASE...END pairs.
                    case_depth = 0
                    for j in range(len(result_lines) - 1, max(-1, len(result_lines) - 50), -1):
                        prev_upper = result_lines[j].strip().upper()
                        # Count ALL END occurrences (including inline CASE closers)
                        # but exclude END TRY/CATCH/IF/LOOP which are structural, not CASE closers
                        all_ends = len(re.findall(r'\bEND\b', prev_upper))
                        excl_ends = len(re.findall(r'\bEND\s+(IF|LOOP|TRY|CATCH)\b', prev_upper))
                        case_depth += max(0, all_ends - excl_ends)
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
                result_lines.append(f"{indent}{stripped}")  # preserve trailing comment
                result_lines.append(f"{indent}BEGIN")
                i += 1
                continue

            # Default: pass through
            result_lines.append(line)
            i += 1

        return '\n'.join(result_lines)

    def _convert_for_loop(self, source: str, ctx: ConversionContext) -> str:
        """Convert FOR i IN start..end LOOP → DECLARE + WHILE.

        Handles both simple identifiers and expressions as loop bounds,
        e.g. FOR i IN 0..TO_NUMBER(n) LOOP or FOR i IN 1..nCnt LOOP.
        """
        def replace_for(m):
            var = m.group(1)
            start = m.group(2).strip()
            end = m.group(3).strip()
            # If end is not a plain integer or simple @variable, cast to INT
            if not re.match(r'^(\d+|@\w+)$', end):
                end = f"CAST({end} AS INT)"
            return (
                f"DECLARE @{var} INT = {start};\n"
                f"WHILE @{var} <= {end}\n"
                f"BEGIN"
            )

        # Match FOR var IN start..end LOOP where start/end can be expressions.
        # Use a non-greedy match for end, anchored by the LOOP keyword.
        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+([\w@]+)\s*\.\.\s*(.+?)\s+LOOP\b',
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

        # Also handle no-argument package calls: pkg.proc; → EXEC [schema].[proc];
        def replace_pkg_call_noargs(m):
            indent = m.group(1)
            pkg_name = m.group(2)
            proc_name = m.group(3)
            skip_prefixes = {'SYS', 'DBA', 'ALL', 'USER', 'V$', 'GV$',
                             'DBMS_OUTPUT', 'DBMS_LOB', 'DBMS_SQL', 'DBMS_LOCK',
                             'UTL_FILE', 'UTL_HTTP'}
            if pkg_name.upper() in skip_prefixes:
                return m.group(0)
            from ..utils import sanitize_name
            schema = ctx.schema_mapping.get(pkg_name.upper(), sanitize_name(pkg_name))
            ctx.package_refs.add(pkg_name.upper())
            return f"{indent}EXEC [{schema}].[{proc_name}];"

        result = re.sub(
            r'^([ \t]*)([A-Z]\w*_PKG)\.(\w+)\s*;',
            replace_pkg_call_noargs,
            result, flags=re.IGNORECASE | re.MULTILINE
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

            # Match SELECT...INTO ...FROM within this statement fragment
            pattern = re.compile(
                r'\bSELECT\b(.*?)\bINTO\s+([\s\S]*?)\bFROM\b',
                re.IGNORECASE | re.DOTALL
            )

            def _strip_col_alias(col: str) -> str:
                """Remove trailing column alias from an expression.

                Oracle allows: expr alias or expr AS alias.
                In T-SQL SELECT @var = expr, aliases are not needed
                and bare aliases after ) cause syntax errors.
                """
                col = col.strip()
                # Remove AS alias (with optional space before AS, e.g. ")AS alias" or ") AS alias")
                col = re.sub(r'\s*AS\s+\w+\s*$', '', col,
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
                    # But retain any comments within the SELECT clause if possible, or just the string
                    return f"SELECT {columns_str}\nFROM"

                vars_str = m.group(2).strip()

                # Strip line comments before splitting to avoid commented-out columns
                # being treated as extra comma-separated items
                columns_no_comments = re.sub(r'--.*$', '', columns_str, flags=re.MULTILINE)
                vars_no_comments = re.sub(r'--.*$', '', vars_str, flags=re.MULTILINE).strip()
                
                # Check if it's actually a valid variables list (all starting with @)
                if not re.match(r'^@\w+(?:\s*,\s*@\w+)*$', vars_no_comments):
                    return m.group(0)

                # Use paren-aware split so CASE/function commas don't cause mis-splits
                columns = [c.strip() for c in _split_top_level_commas(columns_no_comments) if c.strip()]
                variables = [v.strip() for v in vars_no_comments.split(',')]

                if len(columns) != len(variables):
                    return m.group(0)

                pairs = [f"{var} = {_strip_col_alias(col)}"
                         for var, col in zip(variables, columns)]
                
                # We output on a single line to avoid _add_set_keyword incorrectly prepending SET
                # to lines that start with @var = in a multiline SELECT statement.
                return "SELECT " + ", ".join(pairs) + " FROM"

            result_parts.append(pattern.sub(replace_select_into, part))

        return ''.join(result_parts)

    def _fix_derived_table_aliases(self, source: str) -> str:
        """Add AS __dcN alias to FROM (...); patterns that are missing aliases.

        T-SQL requires aliases on all derived tables in FROM clauses.
        Uses balanced-paren + string-literal counting for arbitrary nesting depth.
        Applies when matching ')' is immediately followed by ';' (no alias present).
        """
        result = []
        i = 0
        dc_ctr = 0
        from_pat = re.compile(r'\bFROM\s*\(', re.IGNORECASE)

        while i < len(source):
            m = from_pat.search(source, i)
            if not m:
                result.append(source[i:])
                break

            # Emit text before 'FROM ('
            result.append(source[i:m.end()])

            # Find matching ')' using balanced-paren counting, skipping string literals
            open_pos = m.end() - 1  # position of '('
            j = open_pos + 1
            depth = 1
            in_str = False
            while j < len(source) and depth > 0:
                c = source[j]
                if in_str:
                    if c == "'":
                        if j + 1 < len(source) and source[j + 1] == "'":
                            j += 2  # skip escaped ''
                            continue
                        in_str = False
                else:
                    if c == "'":
                        in_str = True
                    elif c == '(':
                        depth += 1
                    elif c == ')':
                        depth -= 1
                        if depth == 0:
                            break
                j += 1

            # j is at the matching ')'
            content = source[m.end():j]  # content inside FROM (...)

            # Check: is the subquery SELECT-based (not a function call like IN (1,2,3))
            is_select = bool(re.match(r'\s*(?:SELECT|WITH)\b', content, re.IGNORECASE))
            # Check: does the matching ')' immediately precede ';' (no alias after it)
            after = source[j + 1:j + 20]
            ends_stmt = bool(re.match(r'\s*;', after))

            if is_select and ends_stmt:
                dc_ctr += 1
                result.append(f"{content}) AS __dc{dc_ctr}")
                i = j + 1  # skip past ')'
            else:
                # Not a target — emit content and ')' normally
                result.append(content)
                result.append(')')
                i = j + 1

        return ''.join(result)

    def _fix_exec_expressions(self, source: str) -> str:
        """Pre-declare expression args in EXEC [schema].[proc] calls.

        T-SQL EXEC positional args cannot be expressions (e.g. @var + 'str').
        Finds each EXEC statement, parses args (string-literal-aware), and
        pre-declares any expression arg as a local variable.
        """
        _ctr = [0]
        exec_pat = re.compile(r'\bEXEC\s+(\[[\w_]+\]\.\[[\w_]+\])\s+', re.IGNORECASE)

        result = []
        pos = 0

        while pos < len(source):
            m = exec_pat.search(source, pos)
            if not m:
                result.append(source[pos:])
                break

            # Emit text before EXEC
            result.append(source[pos:m.start()])

            # Find the ';' ending this EXEC (string-literal-aware)
            j = m.end()
            in_str = False
            stmt_end = None
            while j < len(source):
                c = source[j]
                if in_str:
                    if c == "'":
                        if j + 1 < len(source) and source[j + 1] == "'":
                            j += 2
                            continue
                        in_str = False
                else:
                    if c == "'":
                        in_str = True
                    elif c == ';':
                        stmt_end = j
                        break
                j += 1

            if stmt_end is None:
                result.append(source[m.start():])
                pos = len(source)
                break

            args_raw = source[m.end():stmt_end]

            # Split args by ',' (string-literal and paren-depth aware)
            args = []
            current = []
            in_s = False
            depth = 0
            k = 0
            while k < len(args_raw):
                c = args_raw[k]
                if in_s:
                    current.append(c)
                    if c == "'":
                        if k + 1 < len(args_raw) and args_raw[k + 1] == "'":
                            current.append("'")
                            k += 2
                            continue
                        in_s = False
                else:
                    if c == "'":
                        in_s = True
                        current.append(c)
                    elif c == '(':
                        depth += 1
                        current.append(c)
                    elif c == ')':
                        depth -= 1
                        current.append(c)
                    elif c == ',' and depth == 0:
                        args.append(''.join(current))
                        current = []
                        k += 1
                        continue
                    else:
                        current.append(c)
                k += 1
            if current:
                args.append(''.join(current))

            # Check each arg for '+' outside string literals / parens
            decls = []
            new_args = []
            changed = False
            for arg in args:
                arg_str = arg.strip()
                # Detect '+' outside strings and parens
                has_plus = False
                in_s2 = False
                depth2 = 0
                for c in arg_str:
                    if in_s2:
                        if c == "'":
                            in_s2 = False
                    else:
                        if c == "'":
                            in_s2 = True
                        elif c == '(':
                            depth2 += 1
                        elif c == ')':
                            depth2 -= 1
                        elif c == '+' and depth2 == 0:
                            has_plus = True
                            break
                if has_plus:
                    _ctr[0] += 1
                    var = f"@__xe{_ctr[0]}"
                    decls.append(f"DECLARE {var} NVARCHAR(MAX) = {arg_str};")
                    new_args.append(var)
                    changed = True
                else:
                    new_args.append(arg_str)

            if changed:
                # Find indentation of EXEC line
                line_start = source.rfind('\n', 0, m.start())
                exec_line_prefix = source[line_start + 1:m.start()]
                indent = re.match(r'^[ \t]*', exec_line_prefix).group(0)
                decl_block = '\n'.join(f"{indent}{d}" for d in decls)
                new_args_str = ', '.join(new_args)
                result.append(f"{decl_block}\n{indent}{m.group(0)}{new_args_str};")
            else:
                result.append(source[m.start():stmt_end + 1])

            pos = stmt_end + 1

        return ''.join(result)

    def _wrap_top_level_try_catch(self, source: str) -> str:
        """Wrap top-level TRY/CATCH in BEGIN...END when DECLARE precedes BEGIN TRY.

        T-SQL stored procedures fail to parse (error 102 near ';' and 'CATCH')
        when DECLARE statements appear directly before BEGIN TRY without an
        enclosing BEGIN...END block. SSMA always adds this wrapper.
        """
        lines = source.split('\n')
        result = []
        i = 0

        while i < len(lines):
            line = lines[i]
            stripped = line.strip().upper()

            # Detect the AS line belonging to a CREATE OR ALTER PROCEDURE/FUNCTION
            if stripped == 'AS':
                is_proc_as = any(
                    re.match(r'\s*CREATE\s+OR\s+ALTER\s+(PROCEDURE|FUNCTION)\b', lines[j], re.IGNORECASE)
                    for j in range(max(0, i - 10), i + 1)
                )
                if is_proc_as:
                    result.append(line)
                    i += 1
                    # Collect DECLARE/comment/empty lines after AS
                    declare_block = []
                    j = i
                    begin_try_idx = None
                    while j < len(lines):
                        s = lines[j].strip()
                        su = s.upper()
                        if not s or s.startswith('--'):
                            declare_block.append(lines[j])
                            j += 1
                        elif su.startswith('DECLARE ') or su == 'DECLARE':
                            declare_block.append(lines[j])
                            j += 1
                        elif re.match(r'BEGIN\s+TRY\b', s, re.IGNORECASE):
                            begin_try_idx = j
                            break
                        else:
                            break  # outer BEGIN or something else — don't wrap

                    if begin_try_idx is None:
                        result.extend(declare_block)
                        i = j
                        continue

                    # Find the matching END CATCH for the outermost BEGIN TRY
                    # Track nesting: BEGIN TRY increments, END TRY decrements
                    # When depth reaches 0 after END TRY, the next END CATCH is ours
                    end_catch_idx = None
                    depth = 0
                    for k in range(begin_try_idx, len(lines)):
                        if re.match(r'^\s*GO\s*$', lines[k]):
                            break
                        ks = lines[k].strip()
                        if re.match(r'BEGIN\s+TRY\b', ks, re.IGNORECASE):
                            depth += 1
                        elif re.match(r'END\s+TRY\b', ks, re.IGNORECASE):
                            depth -= 1
                        elif re.match(r'END\s+CATCH\b', ks, re.IGNORECASE) and depth == 0:
                            end_catch_idx = k
                            break

                    if end_catch_idx is None:
                        result.extend(declare_block)
                        i = j
                        continue

                    # Determine indent from BEGIN TRY line
                    bt_line = lines[begin_try_idx]
                    indent = bt_line[:len(bt_line) - len(bt_line.lstrip())]

                    # Output: declare block + BEGIN wrapper + TRY body + END wrapper
                    result.extend(declare_block)
                    result.append(f'{indent}BEGIN')
                    for idx in range(begin_try_idx, end_catch_idx + 1):
                        result.append(lines[idx])
                    result.append(f'{indent}END')
                    i = end_catch_idx + 1
                    continue

            result.append(line)
            i += 1

        return '\n'.join(result)

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
