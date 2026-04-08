"""
Main syntax transformer: Oracle PL/SQL → MSSQL T-SQL using ANTLR4 parse tree.

Strategy: TokenStreamRewriter for token-level changes +
           targeted visitor methods for structural changes.
"""
from __future__ import annotations
import re
from typing import Optional

from antlr4.TokenStreamRewriter import TokenStreamRewriter
from antlr4 import ParseTreeVisitor
from antlr4.Token import CommonToken

from .type_mapper import map_type
from .declaration_collector import DeclarationCollector, VarDecl


# Oracle functions → T-SQL equivalents (simple, no-arg-change)
FUNC_MAP_SIMPLE = {
    "SYSDATE": "GETDATE()",
    "SYSTIMESTAMP": "SYSDATETIMEOFFSET()",
    "CURRENT_TIMESTAMP": "SYSDATETIMEOFFSET()",
    "USER": "SYSTEM_USER",
    "SYS_GUID": "NEWID()",
    "ROWNUM": "ROW_NUMBER() OVER (ORDER BY (SELECT NULL))",
    "SQLCODE": "ERROR_NUMBER()",
    "SQLERRM": "ERROR_MESSAGE()",
}

# Oracle date format → .NET/T-SQL format
DATE_FORMAT_MAP = {
    "YYYY": "yyyy", "YY": "yy", "RRRR": "yyyy", "RR": "yy",
    "MM": "MM", "MON": "MMM", "MONTH": "MMMM",
    "DD": "dd", "DY": "ddd", "DAY": "dddd",
    "HH24": "HH", "HH12": "hh", "HH": "hh",
    "MI": "mm", "SS": "ss",
    "FF": "fffffff", "FF3": "fff", "FF6": "ffffff",
    "AM": "tt", "PM": "tt", "A.M.": "tt", "P.M.": "tt",
}


def _oracle_fmt_to_net(oracle_fmt: str) -> str:
    result = oracle_fmt
    for ora, net in sorted(DATE_FORMAT_MAP.items(), key=lambda x: -len(x[0])):
        result = result.replace(ora, net)
    return result


def _split_args(s: str) -> list[str]:
    """Split comma-separated args respecting nested parentheses and quotes."""
    args = []
    depth = 0
    buf = []
    in_str = False
    str_char = ''
    for ch in s:
        if in_str:
            buf.append(ch)
            if ch == str_char:
                in_str = False
        elif ch in ("'", '"'):
            in_str = True
            str_char = ch
            buf.append(ch)
        elif ch == '(':
            depth += 1
            buf.append(ch)
        elif ch == ')':
            depth -= 1
            buf.append(ch)
        elif ch == ',' and depth == 0:
            args.append(''.join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    if buf:
        args.append(''.join(buf).strip())
    return args


def _extract_func_args(s: str, start: int) -> tuple[str, int]:
    """Extract the full argument string from pos start (after opening '(').
    Returns (inner_content, end_pos) where end_pos is after the closing ')'.
    """
    depth = 1
    j = start
    in_str = False
    str_char = ''
    while j < len(s) and depth > 0:
        ch = s[j]
        if in_str:
            if ch == str_char:
                in_str = False
        elif ch in ("'", '"'):
            in_str, str_char = True, ch
        elif ch == '(':
            depth += 1
        elif ch == ')':
            depth -= 1
        j += 1
    return s[start:j - 1], j


def _convert_func_calls(s: str, func_name: str, converter) -> str:
    """Replace all occurrences of func_name(...) using a paren-aware extractor."""
    result = []
    i = 0
    pat = re.compile(r'\b' + re.escape(func_name) + r'\s*\(', re.IGNORECASE)
    while i < len(s):
        m = pat.search(s, i)
        if not m:
            result.append(s[i:])
            break
        result.append(s[i:m.start()])
        inner, end = _extract_func_args(s, m.end())
        result.append(converter(inner))
        i = end
    return ''.join(result)


def _to_char_convert(inner: str) -> str:
    args = _split_args(inner)
    if len(args) >= 2:
        expr = args[0].strip()
        fmt = args[1].strip().strip("'\"")
        net_fmt = _oracle_fmt_to_net(fmt)
        return f"FORMAT({expr}, '{net_fmt}')"
    return f"CAST({inner.strip()} AS NVARCHAR)"


def _to_date_convert(inner: str) -> str:
    args = _split_args(inner)
    expr = args[0].strip() if args else inner.strip()
    return f"CONVERT(DATETIME2, {expr})"


def _to_number_convert(inner: str) -> str:
    return f"CAST({inner.strip()} AS DECIMAL(38,10))"


def _convert_decode_in_text(s: str) -> str:
    """Convert DECODE(expr, v1, r1, ..., default) → CASE WHEN expr=v1 THEN r1 ... END."""
    result = []
    i = 0
    pattern = re.compile(r'\bDECODE\s*\(', re.IGNORECASE)
    while i < len(s):
        m = pattern.search(s, i)
        if not m:
            result.append(s[i:])
            break
        result.append(s[i:m.start()])
        # Find matching closing paren
        start = m.end()
        depth = 1
        j = start
        in_str = False
        str_char = ''
        while j < len(s) and depth > 0:
            ch = s[j]
            if in_str:
                if ch == str_char:
                    in_str = False
            elif ch in ("'", '"'):
                in_str = True
                str_char = ch
            elif ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            j += 1
        inner = s[start:j - 1]
        args = _split_args(inner)
        if len(args) < 3:
            result.append(f"DECODE({inner})")
        else:
            expr = args[0]
            pairs = args[1:]
            case_parts = [f"CASE"]
            k = 0
            while k + 1 < len(pairs):
                case_parts.append(f" WHEN {expr} = {pairs[k]} THEN {pairs[k+1]}")
                k += 2
            if k < len(pairs):
                case_parts.append(f" ELSE {pairs[k]}")
            case_parts.append(" END")
            result.append(''.join(case_parts))
        i = j
    return ''.join(result)


class SyntaxTransformer:
    """
    Applies Oracle → MSSQL syntactic transformations to a routine's token stream.

    Usage:
        transformer = SyntaxTransformer(tokens, stream, pkg_name, routine_name)
        tsql = transformer.transform(routine_ctx)
    """

    def __init__(self, tokens, stream, pkg_name: str, routine_name: str,
                 all_vars: Optional[set[str]] = None,
                 all_params: Optional[set[str]] = None):
        self.tokens = tokens
        self.stream = stream
        self.rewriter = TokenStreamRewriter(stream)
        self.pkg_name = pkg_name
        self.routine_name = routine_name
        # Set of local variable names (for @ prefix in T-SQL)
        self.all_vars: set[str] = all_vars or set()
        self.all_params: set[str] = all_params or set()

    def transform(self, routine_ctx) -> str:
        """Transform a procedure_body/function_body ctx and return T-SQL string."""
        from ora2mssql.parser.PlSqlParser import PlSqlParser

        # Collect declarations first
        collector = DeclarationCollector()
        decls = collector.collect(routine_ctx)

        # Update var set
        for d in decls:
            self.all_vars.add(d.name.upper())

        # Walk tree and apply rewriter transformations
        self._walk(routine_ctx)

        # Get the rewritten text for the routine's token range
        start = routine_ctx.start.tokenIndex
        stop = routine_ctx.stop.tokenIndex
        raw = self.rewriter.getText(
            program_name=TokenStreamRewriter.DEFAULT_PROGRAM_NAME,
            interval=(start, stop)
        )

        # Post-process: structural transforms that are easier as text
        result = self._post_process(raw, decls, routine_ctx)
        return result

    # ------------------------------------------------------------------
    # Tree walker — applies token-level rewrites
    # ------------------------------------------------------------------

    def _walk(self, ctx):
        from ora2mssql.parser.PlSqlParser import PlSqlParser

        if not hasattr(ctx, 'children') or ctx.children is None:
            return

        for child in ctx.children:
            # Data type rewrites
            if isinstance(child, (PlSqlParser.Type_specContext,
                                   PlSqlParser.DatatypeContext)):
                self._rewrite_type(child)

            # Assignment :=
            elif isinstance(child, PlSqlParser.Assignment_statementContext):
                self._rewrite_assignment(child)

            # IF statement
            elif isinstance(child, PlSqlParser.If_statementContext):
                self._rewrite_if(child)
                self._walk(child)
                continue

            # LOOP / FOR / WHILE
            elif isinstance(child, PlSqlParser.Simple_loop_statementContext):
                self._rewrite_simple_loop(child)
            elif isinstance(child, PlSqlParser.For_loop_statementContext):
                self._rewrite_for_loop(child)
            elif isinstance(child, PlSqlParser.While_loop_statementContext):
                self._rewrite_while_loop(child)

            # EXCEPTION block
            elif isinstance(child, PlSqlParser.Exception_handlerContext):
                self._rewrite_exception_handler(child)

            # Function calls (NVL, TO_CHAR, etc.)
            elif isinstance(child, PlSqlParser.Function_callContext):
                self._rewrite_function_call(child)
            elif isinstance(child, PlSqlParser.Standard_functionContext):
                self._rewrite_standard_function(child)
            elif isinstance(child, PlSqlParser.General_element_partContext):
                self._rewrite_general_element(child)

            # COMMIT / ROLLBACK / SAVEPOINT
            elif isinstance(child, PlSqlParser.Commit_statementContext):
                self._rewrite_commit(child)
            elif isinstance(child, PlSqlParser.Rollback_statementContext):
                self._rewrite_rollback(child)
            elif isinstance(child, PlSqlParser.Savepoint_statementContext):
                self._rewrite_savepoint(child)

            # RAISE
            elif isinstance(child, PlSqlParser.Raise_statementContext):
                self._rewrite_raise(child)

            # EXIT WHEN
            elif isinstance(child, PlSqlParser.Exit_statementContext):
                self._rewrite_exit(child)

            # CONTINUE
            elif isinstance(child, PlSqlParser.Continue_statementContext):
                self._rewrite_continue(child)

            self._walk(child)

    # ------------------------------------------------------------------
    # Token-level rewrite methods
    # ------------------------------------------------------------------

    def _rewrite_type(self, ctx):
        """Rewrite data type node."""
        oracle_type = ctx.getText()
        mssql_type = map_type(oracle_type)
        if mssql_type != oracle_type:
            self.rewriter.replaceRange(
                ctx.start.tokenIndex,
                ctx.stop.tokenIndex,
                mssql_type
            )

    def _rewrite_assignment(self, ctx):
        """x := expr; → SET @x = expr; (inside body)"""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        # Find the := token
        for i in range(ctx.start.tokenIndex, ctx.stop.tokenIndex + 1):
            tok = self.tokens[i]
            if tok.text == ":=":
                self.rewriter.replaceSingleToken(tok, "=")
                # Insert SET @var before the variable
                # The variable is the first child
                if ctx.children:
                    first = ctx.start
                    var_name = ctx.children[0].getText()
                    # Add SET and @ prefix
                    self.rewriter.insertBeforeToken(first, "SET ")
                    self.rewriter.replaceSingleToken(first, f"@{var_name}")
                break

    def _rewrite_if(self, ctx):
        """IF cond THEN ... [ELSIF...] [ELSE...] END IF → T-SQL IF..BEGIN..END"""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        # Find THEN tokens and replace with BEGIN
        for i in range(ctx.start.tokenIndex, ctx.stop.tokenIndex + 1):
            tok = self.tokens[i]
            if tok.text.upper() == "THEN":
                self.rewriter.replaceSingleToken(tok, "BEGIN")
            elif tok.text.upper() == "ELSIF":
                # Replace ELSIF with END ELSE IF
                self.rewriter.replaceSingleToken(tok, "END\nELSE IF")
            elif tok.text.upper() == "END" and i + 1 <= ctx.stop.tokenIndex:
                # Check next non-whitespace token
                next_tok = self._next_real_token(i + 1, ctx.stop.tokenIndex)
                if next_tok and next_tok.text.upper() == "IF":
                    self.rewriter.replaceSingleToken(tok, "END")
                    self.rewriter.deleteToken(next_tok)

    def _rewrite_simple_loop(self, ctx):
        """LOOP ... END LOOP → WHILE 1=1 BEGIN ... END"""
        for i in range(ctx.start.tokenIndex, ctx.stop.tokenIndex + 1):
            tok = self.tokens[i]
            if tok.text.upper() == "LOOP" and i == ctx.start.tokenIndex:
                self.rewriter.replaceSingleToken(tok, "WHILE 1=1 BEGIN")
            elif tok.text.upper() == "END":
                next_tok = self._next_real_token(i + 1, ctx.stop.tokenIndex)
                if next_tok and next_tok.text.upper() == "LOOP":
                    self.rewriter.replaceSingleToken(tok, "END")
                    self.rewriter.deleteToken(next_tok)

    def _rewrite_for_loop(self, ctx):
        """FOR i IN lower..upper LOOP → DECLARE/SET + WHILE"""
        # Complex transformation — emit comment for manual review
        self.rewriter.insertBeforeToken(
            ctx.start,
            "/* TODO: Convert FOR loop */ "
        )

    def _rewrite_while_loop(self, ctx):
        """WHILE cond LOOP → WHILE cond BEGIN"""
        for i in range(ctx.start.tokenIndex, ctx.stop.tokenIndex + 1):
            tok = self.tokens[i]
            if tok.text.upper() == "LOOP":
                self.rewriter.replaceSingleToken(tok, "BEGIN")
            elif tok.text.upper() == "END":
                next_tok = self._next_real_token(i + 1, ctx.stop.tokenIndex)
                if next_tok and next_tok.text.upper() == "LOOP":
                    self.rewriter.replaceSingleToken(tok, "END")
                    self.rewriter.deleteToken(next_tok)

    def _rewrite_exception_handler(self, ctx):
        """EXCEPTION WHEN ... → END TRY BEGIN CATCH ... END CATCH"""
        # Mark the exception block for post-processing
        # (structural change handled in _post_process)
        self.rewriter.insertBeforeToken(
            ctx.start,
            "/*EXCEPTION_BLOCK_START*/ "
        )

    def _rewrite_function_call(self, ctx):
        """Rewrite known Oracle function calls."""
        name = ctx.children[0].getText().upper() if ctx.children else ""
        if name == "DBMS_OUTPUT.PUT_LINE":
            # Replace with PRINT
            name_tok = ctx.start
            self.rewriter.replaceSingleToken(name_tok, "PRINT")
        elif name == "NVL":
            self.rewriter.replaceSingleToken(ctx.start, "ISNULL")
        elif name == "NVL2":
            self.rewriter.insertBeforeToken(ctx.start, "/*NVL2→IIF*/ IIF(")

    def _rewrite_standard_function(self, ctx):
        """Rewrite Oracle standard functions."""
        text = ctx.getText().upper()
        # SYSDATE
        if text == "SYSDATE":
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex, "GETDATE()"
            )
        elif text == "SYSTIMESTAMP":
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex, "SYSDATETIMEOFFSET()"
            )

    def _rewrite_general_element(self, ctx):
        """Rewrite package-level element references like SYSDATE."""
        text = ctx.getText().upper()
        if text in FUNC_MAP_SIMPLE:
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex,
                FUNC_MAP_SIMPLE[text]
            )

    def _rewrite_commit(self, ctx):
        """COMMIT [WORK] → COMMIT TRAN"""
        self.rewriter.replaceRange(
            ctx.start.tokenIndex, ctx.stop.tokenIndex, "COMMIT TRAN"
        )

    def _rewrite_rollback(self, ctx):
        """ROLLBACK [WORK] [TO savepoint] → ROLLBACK TRAN [savepoint]"""
        text = ctx.getText().upper()
        if "TO" in text:
            # ROLLBACK TO SAVEPOINT sp1 → ROLLBACK TRAN sp1
            m = re.search(r'TO\s+(?:SAVEPOINT\s+)?(\w+)', text, re.IGNORECASE)
            sp = m.group(1) if m else ""
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex,
                f"ROLLBACK TRAN {sp}"
            )
        else:
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex, "ROLLBACK TRAN"
            )

    def _rewrite_savepoint(self, ctx):
        """SAVEPOINT sp → SAVE TRAN sp"""
        text = ctx.getText()
        # extract savepoint name
        m = re.match(r'SAVEPOINT\s+(\w+)', text, re.IGNORECASE)
        sp = m.group(1) if m else "SP"
        self.rewriter.replaceRange(
            ctx.start.tokenIndex, ctx.stop.tokenIndex, f"SAVE TRAN {sp}"
        )

    def _rewrite_raise(self, ctx):
        """RAISE exception_name → RAISERROR(...)"""
        text = ctx.getText()
        m = re.match(r'RAISE\s+(\w+)', text, re.IGNORECASE)
        if m:
            exc_name = m.group(1)
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex,
                f"RAISERROR(N'{exc_name}', 16, 1)"
            )
        else:
            # bare RAISE inside exception handler → THROW
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex, "THROW"
            )

    def _rewrite_exit(self, ctx):
        """EXIT [WHEN cond] → IF cond BREAK / BREAK"""
        text = ctx.getText()
        if re.search(r'WHEN', text, re.IGNORECASE):
            m = re.match(r'EXIT\s+(?:\w+\s+)?WHEN\s+(.*)', text, re.IGNORECASE)
            cond = m.group(1).rstrip(";") if m else "1=1"
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex,
                f"IF {cond} BREAK"
            )
        else:
            self.rewriter.replaceRange(
                ctx.start.tokenIndex, ctx.stop.tokenIndex, "BREAK"
            )

    def _rewrite_continue(self, ctx):
        """CONTINUE → CONTINUE (T-SQL 2012+)"""
        # T-SQL supports CONTINUE natively — no change needed
        pass

    # ------------------------------------------------------------------
    # Post-processing (text-level structural transforms)
    # ------------------------------------------------------------------

    def _post_process(self, raw: str, decls: list[VarDecl], routine_ctx) -> str:
        """Apply structural transforms after token-level rewrites."""
        result = raw

        # 1. Convert function calls: NVL, TO_CHAR, TRUNC, LAST_DAY, etc.
        result = self._convert_functions(result)

        # 2. Fix boolean comparisons
        result = self._fix_boolean(result)

        # 3. String concatenation || → +
        result = result.replace("||", "+")

        # 4. Remove Oracle-specific keywords
        result = re.sub(r'\bIS\s+NULL\b', 'IS NULL', result, flags=re.IGNORECASE)
        result = re.sub(r'\bNOT\s+NULL\b', 'IS NOT NULL', result, flags=re.IGNORECASE)

        # 5. Fix EXCEPTION blocks → TRY/CATCH
        result = self._convert_exception_blocks(result)

        # 6. Clean up semicolons at end of blocks
        result = re.sub(r';\s*$', '', result, flags=re.MULTILINE)

        return result

    def _convert_functions(self, s: str) -> str:
        """Convert Oracle built-in functions to T-SQL equivalents."""

        # SYSDATE → GETDATE()
        s = re.sub(r'\bSYSDATE\b', 'GETDATE()', s, flags=re.IGNORECASE)
        s = re.sub(r'\bSYSTIMESTAMP\b', 'SYSDATETIMEOFFSET()', s, flags=re.IGNORECASE)

        # NVL(a, b) → ISNULL(a, b)
        s = re.sub(r'\bNVL\s*\(', 'ISNULL(', s, flags=re.IGNORECASE)

        # NVL2(expr, val_if_not_null, val_if_null) → IIF(expr IS NOT NULL, val_if_not_null, val_if_null)
        s = re.sub(r'\bNVL2\s*\(', '/*NVL2*/ IIF(', s, flags=re.IGNORECASE)

        # DECODE(expr, v1, r1, v2, r2, ..., default) → CASE WHEN expr=v1 THEN r1 ... ELSE default END
        s = _convert_decode_in_text(s)

        # TO_CHAR / TO_DATE / TO_NUMBER — use paren-aware extractor for nested calls
        s = _convert_func_calls(s, 'TO_CHAR', _to_char_convert)
        s = _convert_func_calls(s, 'TO_DATE', _to_date_convert)
        s = _convert_func_calls(s, 'TO_NUMBER', _to_number_convert)

        # TRUNC(date) → CAST(date AS DATE)
        s = re.sub(r'\bTRUNC\s*\(([^,)]+)\)',
                   lambda m: f"CAST({m.group(1).strip()} AS DATE)",
                   s, flags=re.IGNORECASE)

        # CEIL(x) → CEILING(x)
        s = re.sub(r'\bCEIL\s*\(', 'CEILING(', s, flags=re.IGNORECASE)

        # LAST_DAY(date) → EOMONTH(date)
        s = re.sub(r'\bLAST_DAY\s*\(', 'EOMONTH(', s, flags=re.IGNORECASE)

        # MONTHS_BETWEEN(d1, d2) → DATEDIFF(MONTH, d2, d1)
        def months_between(m):
            args = m.group(1).split(',', 1)
            if len(args) == 2:
                return f"DATEDIFF(MONTH, {args[1].strip()}, {args[0].strip()})"
            return f"/*MONTHS_BETWEEN*/ {m.group(0)}"
        s = re.sub(r'\bMONTHS_BETWEEN\s*\(([^)]+)\)', months_between, s, flags=re.IGNORECASE)

        # ADD_MONTHS(date, n) → DATEADD(MONTH, n, date)
        def add_months(m):
            args = m.group(1).split(',', 1)
            if len(args) == 2:
                return f"DATEADD(MONTH, {args[1].strip()}, {args[0].strip()})"
            return m.group(0)
        s = re.sub(r'\bADD_MONTHS\s*\(([^)]+)\)', add_months, s, flags=re.IGNORECASE)

        # INSTR(str, sub) → CHARINDEX(sub, str)
        def instr_replace(m):
            args = m.group(1).split(',', 1)
            if len(args) == 2:
                return f"CHARINDEX({args[1].strip()}, {args[0].strip()})"
            return m.group(0)
        s = re.sub(r'\bINSTR\s*\(([^)]+)\)', instr_replace, s, flags=re.IGNORECASE)

        # SUBSTR(str, start, len) → SUBSTRING(str, start, len)
        s = re.sub(r'\bSUBSTR\s*\(', 'SUBSTRING(', s, flags=re.IGNORECASE)

        # LENGTH(str) → LEN(str)
        s = re.sub(r'\bLENGTH\s*\(', 'LEN(', s, flags=re.IGNORECASE)

        # LTRIM / RTRIM — same in T-SQL
        # TRIM(x) → LTRIM(RTRIM(x))
        s = re.sub(r'\bTRIM\s*\(([^)]+)\)',
                   lambda m: f"LTRIM(RTRIM({m.group(1)}))",
                   s, flags=re.IGNORECASE)

        # UPPER / LOWER — same in T-SQL
        # LPAD(str, len, pad) → T-SQL equivalent
        def lpad_replace(m):
            args = [a.strip() for a in m.group(1).split(',')]
            if len(args) >= 2:
                str_val = args[0]
                length = args[1]
                pad = args[2] if len(args) > 2 else "' '"
                return f"RIGHT(REPLICATE({pad}, {length}) + {str_val}, {length})"
            return m.group(0)
        s = re.sub(r'\bLPAD\s*\(([^)]+)\)', lpad_replace, s, flags=re.IGNORECASE)

        # RPAD(str, len, pad)
        def rpad_replace(m):
            args = [a.strip() for a in m.group(1).split(',')]
            if len(args) >= 2:
                str_val = args[0]
                length = args[1]
                pad = args[2] if len(args) > 2 else "' '"
                return f"LEFT({str_val} + REPLICATE({pad}, {length}), {length})"
            return m.group(0)
        s = re.sub(r'\bRPAD\s*\(([^)]+)\)', rpad_replace, s, flags=re.IGNORECASE)

        # DBMS_OUTPUT.PUT_LINE(x) → PRINT x
        s = re.sub(
            r'\bDBMS_OUTPUT\s*\.\s*PUT_LINE\s*\(([^)]+)\)',
            lambda m: f"PRINT {m.group(1)}",
            s, flags=re.IGNORECASE
        )
        s = re.sub(
            r'\bDBMS_OUTPUT\s*\.\s*PUT\s*\(([^)]+)\)',
            lambda m: f"PRINT {m.group(1)}",
            s, flags=re.IGNORECASE
        )

        # IN 'value' without parentheses → IN ('value')
        # Oracle allows both; T-SQL requires parentheses
        s = re.sub(r"\bIN\s+'([^']*)'", r"IN ('\1')", s, flags=re.IGNORECASE)
        s = re.sub(r'\bIN\s+(\d+)\b', r'IN (\1)', s, flags=re.IGNORECASE)

        # RAISE_APPLICATION_ERROR(num, msg) → RAISERROR(msg, 16, 1)
        def raise_app_error(m):
            args = [a.strip() for a in m.group(1).split(',', 1)]
            msg = args[1] if len(args) > 1 else "'Application error'"
            return f"RAISERROR({msg}, 16, 1)"
        s = re.sub(r'\bRAISE_APPLICATION_ERROR\s*\(([^)]+)\)',
                   raise_app_error, s, flags=re.IGNORECASE)

        return s

    def _fix_boolean(self, s: str) -> str:
        """Fix Oracle BOOLEAN → T-SQL BIT comparisons."""
        s = re.sub(r'\bTRUE\b', '1', s, flags=re.IGNORECASE)
        s = re.sub(r'\bFALSE\b', '0', s, flags=re.IGNORECASE)
        return s

    def _convert_exception_blocks(self, s: str) -> str:
        """
        Convert Oracle EXCEPTION block to T-SQL TRY/CATCH.

        Oracle:
            BEGIN
                ...body...
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ...handler...
                WHEN OTHERS THEN
                    ...handler...
            END;

        T-SQL:
            BEGIN TRY
                ...body...
            END TRY
            BEGIN CATCH
                IF ERROR_NUMBER() = ... BEGIN ... END
                ...
            END CATCH
        """
        # Look for the exception block marker we inserted
        if "/*EXCEPTION_BLOCK_START*/" not in s:
            return s

        # Split at the exception block marker
        parts = s.split("/*EXCEPTION_BLOCK_START*/", 1)
        before = parts[0]
        after = parts[1]

        # Find the matching BEGIN before the exception block
        # and wrap it with TRY/CATCH
        # This is a heuristic: find the last BEGIN before EXCEPTION
        exc_body = after
        # Convert WHEN NO_DATA_FOUND THEN → IF ERROR_NUMBER() = 1403 BEGIN
        # Convert WHEN OTHERS THEN → (else part of CATCH)
        exc_body = re.sub(
            r'\bWHEN\s+NO_DATA_FOUND\s+THEN\b',
            'IF ERROR_NUMBER() IN (1403, 100) BEGIN',
            exc_body, flags=re.IGNORECASE
        )
        exc_body = re.sub(
            r'\bWHEN\s+DUP_VAL_ON_INDEX\s+THEN\b',
            'IF ERROR_NUMBER() = 2601 BEGIN',
            exc_body, flags=re.IGNORECASE
        )
        exc_body = re.sub(
            r'\bWHEN\s+OTHERS\s+THEN\b',
            '/* WHEN OTHERS */',
            exc_body, flags=re.IGNORECASE
        )
        exc_body = re.sub(
            r'\bWHEN\s+(\w+)\s+THEN\b',
            lambda m: f'/* WHEN {m.group(1)} */',
            exc_body, flags=re.IGNORECASE
        )

        return before + "\nEND TRY\nBEGIN CATCH\n" + exc_body

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def _next_real_token(self, start_idx: int, max_idx: int):
        """Return first non-whitespace, non-newline token at or after start_idx."""
        for i in range(start_idx, max_idx + 1):
            if i >= len(self.tokens):
                break
            tok = self.tokens[i]
            if tok.channel == 0 and tok.text.strip():
                return tok
        return None
