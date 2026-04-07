"""Built-in function mapping: Oracle → MSSQL."""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


# Oracle date format → .NET format mapping (for FORMAT())
DATE_FORMAT_MAP = {
    "YYYY": "yyyy",
    "YY": "yy",
    "RRRR": "yyyy",
    "RR": "yy",
    "MM": "MM",
    "MON": "MMM",
    "MONTH": "MMMM",
    "DD": "dd",
    "DY": "ddd",
    "DAY": "dddd",
    "HH24": "HH",
    "HH12": "hh",
    "HH": "hh",
    "MI": "mm",
    "SS": "ss",
    "FF": "fffffff",
    "FF3": "fff",
    "FF6": "ffffff",
    "AM": "tt",
    "PM": "tt",
    "A.M.": "tt",
    "P.M.": "tt",
}


def _convert_date_format(oracle_fmt: str) -> str:
    """Convert Oracle date format string to .NET format string."""
    result = oracle_fmt
    # Sort by length desc to avoid partial replacements
    for ora, net in sorted(DATE_FORMAT_MAP.items(), key=lambda x: -len(x[0])):
        result = result.replace(ora, net)
    return result


def _parse_balanced_args(source: str, start_pos: int) -> tuple[list[str], int]:
    """Parse comma-separated arguments within balanced parentheses.

    Returns (list of args, position after closing paren).
    """
    if start_pos >= len(source) or source[start_pos] != '(':
        return [], start_pos

    depth = 0
    current_arg = []
    args = []
    i = start_pos

    while i < len(source):
        ch = source[i]
        if ch == '(':
            depth += 1
            if depth > 1:
                current_arg.append(ch)
        elif ch == ')':
            depth -= 1
            if depth == 0:
                args.append(''.join(current_arg).strip())
                return args, i + 1
            current_arg.append(ch)
        elif ch == ',' and depth == 1:
            args.append(''.join(current_arg).strip())
            current_arg = []
        elif ch == "'" :
            # Handle string literals
            current_arg.append(ch)
            i += 1
            while i < len(source) and source[i] != "'":
                current_arg.append(source[i])
                i += 1
            if i < len(source):
                current_arg.append(source[i])
        else:
            current_arg.append(ch)
        i += 1

    return args, i


class FunctionRule(ConversionRule):
    name = "functions"
    order = 30

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = source

        # COUNT(ROWID) → COUNT(*) (Oracle ROWID pseudo-column in aggregate)
        result = re.sub(r'\bCOUNT\s*\(\s*ROWID\s*\)', 'COUNT(*)', result, flags=re.IGNORECASE)

        # Simple replacements (no arg reordering needed)
        result = re.sub(r'\bSYSDATE\b', 'GETDATE()', result, flags=re.IGNORECASE)
        result = re.sub(r'\bSYSTIMESTAMP\b', 'SYSDATETIME()', result, flags=re.IGNORECASE)

        # String concatenation: || → +
        result = re.sub(r'\s*\|\|\s*', ' + ', result)

        # NVL(a, b) → ISNULL(a, b) — also catch nested/remaining NVL
        result = self._replace_func(result, 'NVL', self._convert_nvl)
        # Fallback: simple regex for any remaining NVL not caught by balanced parser
        result = re.sub(r'\bNVL\s*\(', 'ISNULL(', result, flags=re.IGNORECASE)

        # CEIL(x) → CEILING(x)
        result = re.sub(r'\bCEIL\s*\(', 'CEILING(', result, flags=re.IGNORECASE)

        # ROUND(x) with only 1 arg → ROUND(x, 0)  (T-SQL requires 2nd arg)
        result = self._replace_func(result, 'ROUND', self._convert_round)

        # NVL2(a, b, c) → IIF(a IS NOT NULL, b, c)
        result = self._replace_func(result, 'NVL2', self._convert_nvl2)

        # DECODE → CASE
        result = self._replace_func(result, 'DECODE', self._convert_decode)

        # SUBSTR → SUBSTRING
        result = self._replace_func(result, 'SUBSTR', self._convert_substr)

        # INSTR → CHARINDEX (arg order swap)
        result = self._replace_func(result, 'INSTR', self._convert_instr, ctx=ctx)

        # LENGTH → LEN
        result = re.sub(r'\bLENGTH\s*\(', 'LEN(', result, flags=re.IGNORECASE)

        # MOD(a, b) → (a % b)
        result = self._replace_func(result, 'MOD', self._convert_mod)

        # TO_CHAR with date format
        result = self._replace_func(result, 'TO_CHAR', self._convert_to_char, ctx=ctx)

        # TO_DATE (run twice to handle nested TO_DATE inside other converted functions)
        result = self._replace_func(result, 'TO_DATE', self._convert_to_date, ctx=ctx)
        result = self._replace_func(result, 'TO_DATE', self._convert_to_date, ctx=ctx)

        # TO_NUMBER
        result = self._replace_func(result, 'TO_NUMBER', self._convert_to_number)

        # TRUNC (date or number)
        result = self._replace_func(result, 'TRUNC', self._convert_trunc)

        # ADD_MONTHS
        result = self._replace_func(result, 'ADD_MONTHS', self._convert_add_months)

        # MONTHS_BETWEEN
        result = self._replace_func(result, 'MONTHS_BETWEEN', self._convert_months_between)

        # LAST_DAY → EOMONTH
        result = re.sub(r'\bLAST_DAY\s*\(', 'EOMONTH(', result, flags=re.IGNORECASE)

        # LPAD / RPAD
        result = self._replace_func(result, 'LPAD', self._convert_lpad)
        result = self._replace_func(result, 'RPAD', self._convert_rpad)

        # GREATEST / LEAST
        result = self._replace_func(result, 'GREATEST', self._convert_greatest)
        result = self._replace_func(result, 'LEAST', self._convert_least)

        # LISTAGG → STRING_AGG
        result = re.sub(r'\bLISTAGG\s*\(', 'STRING_AGG(', result, flags=re.IGNORECASE)

        # DBMS_OUTPUT.PUT_LINE → PRINT
        result = re.sub(
            r'DBMS_OUTPUT\.PUT_LINE\s*\((.+?)\)\s*;',
            r'PRINT \1;',
            result, flags=re.IGNORECASE
        )

        # RAISE_APPLICATION_ERROR → THROW
        result = re.sub(
            r'RAISE_APPLICATION_ERROR\s*\(\s*(-?\d+)\s*,\s*(.+?)\)\s*;',
            lambda m: f"THROW {50000 + abs(int(m.group(1))) % 1000}, {m.group(2)}, 1;",
            result, flags=re.IGNORECASE
        )

        # REGEXP_LIKE / REGEXP_REPLACE / REGEXP_SUBSTR → flag for review
        for func in ('REGEXP_LIKE', 'REGEXP_REPLACE', 'REGEXP_SUBSTR', 'REGEXP_INSTR', 'REGEXP_COUNT'):
            if re.search(r'\b' + func + r'\b', result, re.IGNORECASE):
                ctx.add_manual_review(f"{func} has no native MSSQL equivalent")
                result = re.sub(
                    r'\b' + func + r'\b',
                    f'{func} /* {MANUAL_REVIEW_TAG} no native MSSQL equivalent */',
                    result, count=1, flags=re.IGNORECASE
                )

        # = NULL / != NULL / <> NULL comparisons → IS NULL / IS NOT NULL
        # Oracle allows = NULL but T-SQL requires IS NULL.
        # Use lookbehind to avoid matching 'IS NULL', 'NOT NULL', and strings.
        result = re.sub(r'(?<![!<>:])\s*=\s*NULL\b', ' IS NULL', result, flags=re.IGNORECASE)
        result = re.sub(r'(?:!=|<>)\s*NULL\b', 'IS NOT NULL', result, flags=re.IGNORECASE)

        return result

    def _replace_func(self, source: str, func_name: str, converter, ctx=None):
        """Find and replace a function call using balanced paren parsing."""
        pattern = re.compile(r'\b' + func_name + r'\s*\(', re.IGNORECASE)
        result = []
        last_end = 0

        for m in pattern.finditer(source):
            if m.start() < last_end:
                continue  # Already consumed by an outer (enclosing) match — skip
            result.append(source[last_end:m.start()])
            # Parse args starting from the opening paren
            paren_start = m.end() - 1  # position of '('
            args, end_pos = _parse_balanced_args(source, paren_start)

            if ctx:
                replacement = converter(args, ctx)
            else:
                replacement = converter(args)
            result.append(replacement)
            last_end = end_pos

        result.append(source[last_end:])
        return ''.join(result)

    def _convert_nvl(self, args):
        if len(args) >= 2:
            return f"ISNULL({args[0]}, {args[1]})"
        return f"ISNULL({', '.join(args)})"

    def _convert_nvl2(self, args):
        if len(args) >= 3:
            return f"IIF({args[0]} IS NOT NULL, {args[1]}, {args[2]})"
        return f"IIF({', '.join(args)})"

    def _convert_decode(self, args):
        if len(args) < 3:
            return f"/* {MANUAL_REVIEW_TAG} DECODE with < 3 args */ DECODE({', '.join(args)})"
        expr = args[0]
        pairs = args[1:]
        parts = [f"CASE {expr}"]
        i = 0
        while i < len(pairs) - 1:
            parts.append(f" WHEN {pairs[i]} THEN {pairs[i+1]}")
            i += 2
        if i < len(pairs):
            parts.append(f" ELSE {pairs[i]}")
        parts.append(" END")
        return "".join(parts)

    def _convert_substr(self, args):
        if len(args) >= 3:
            return f"SUBSTRING({args[0]}, {args[1]}, {args[2]})"
        elif len(args) == 2:
            return f"SUBSTRING({args[0]}, {args[1]}, LEN({args[0]}))"
        return f"SUBSTRING({', '.join(args)})"

    def _convert_instr(self, args, ctx=None):
        if len(args) >= 3:
            # INSTR with start pos or occurrence - use UDF
            if ctx:
                ctx.add_warning("INSTR with 3+ args → using ora_compat.INSTR UDF")
            return f"[ora_compat].[INSTR]({', '.join(args)})"
        elif len(args) == 2:
            # Simple: INSTR(str, sub) → CHARINDEX(sub, str)  -- swapped!
            return f"CHARINDEX({args[1]}, {args[0]})"
        return f"CHARINDEX({', '.join(args)})"

    def _convert_mod(self, args):
        if len(args) >= 2:
            return f"({args[0]} % {args[1]})"
        return f"({', '.join(args)} % 0)"

    def _convert_to_char(self, args, ctx=None):
        if len(args) >= 2:
            fmt = args[1].strip().strip("'")
            mssql_fmt = _convert_date_format(fmt)
            return f"FORMAT({args[0]}, '{mssql_fmt}')"
        elif len(args) == 1:
            return f"CAST({args[0]} AS NVARCHAR(4000))"
        return f"CAST({', '.join(args)} AS NVARCHAR)"

    def _convert_to_date(self, args, ctx=None):
        if len(args) >= 2:
            fmt = args[1].strip().strip("'")
            # Use CONVERT with style numbers for common formats
            style = self._date_format_to_style(fmt)
            if style:
                return f"CONVERT(DATETIME2(0), {args[0]}, {style})"
            mssql_fmt = _convert_date_format(fmt)
            return f"TRY_PARSE({args[0]} AS DATETIME2(0) USING 'zh-TW')"
        elif len(args) == 1:
            return f"CAST({args[0]} AS DATETIME2(0))"
        return f"CAST({', '.join(args)} AS DATETIME2)"

    def _date_format_to_style(self, fmt: str) -> str | None:
        """Map common Oracle date formats to MSSQL CONVERT style numbers."""
        fmt_upper = fmt.upper().replace(" ", "")
        mapping = {
            "YYYY-MM-DD": "23",
            "YYYY/MM/DD": "111",
            "DD/MM/YYYY": "103",
            "MM/DD/YYYY": "101",
            "YYYYMMDD": "112",
            "YYYY-MM-DDHH24:MI:SS": "120",
            "DD-MON-YYYY": "106",
            "DD-MON-YY": "106",
        }
        return mapping.get(fmt_upper)

    def _convert_to_number(self, args):
        if len(args) >= 1:
            return f"CAST({args[0]} AS DECIMAL(38,10))"
        return "CAST(NULL AS DECIMAL)"

    def _convert_trunc(self, args):
        if len(args) >= 2:
            # TRUNC(number, decimals) → ROUND(number, decimals, 1)
            return f"ROUND({args[0]}, {args[1]}, 1)"
        elif len(args) == 1:
            # TRUNC(date) → CAST(date AS DATE) or TRUNC(num) → ROUND(num, 0, 1)
            # Heuristic: if it looks like a date expression
            return f"CAST({args[0]} AS DATE)"
        return f"ROUND({', '.join(args)}, 0, 1)"

    def _convert_add_months(self, args):
        if len(args) >= 2:
            return f"DATEADD(MONTH, {args[1]}, {args[0]})"
        return f"DATEADD(MONTH, 0, {', '.join(args)})"

    def _convert_months_between(self, args):
        if len(args) >= 2:
            return f"DATEDIFF(MONTH, {args[1]}, {args[0]})"
        return f"DATEDIFF(MONTH, NULL, {', '.join(args)})"

    def _convert_lpad(self, args):
        if len(args) >= 3:
            return f"RIGHT(REPLICATE({args[2]}, {args[1]}) + {args[0]}, {args[1]})"
        elif len(args) == 2:
            return f"RIGHT(REPLICATE(' ', {args[1]}) + {args[0]}, {args[1]})"
        return f"/* {MANUAL_REVIEW_TAG} LPAD */ {', '.join(args)}"

    def _convert_rpad(self, args):
        if len(args) >= 3:
            return f"LEFT({args[0]} + REPLICATE({args[2]}, {args[1]}), {args[1]})"
        elif len(args) == 2:
            return f"LEFT({args[0]} + REPLICATE(' ', {args[1]}), {args[1]})"
        return f"/* {MANUAL_REVIEW_TAG} RPAD */ {', '.join(args)}"

    def _convert_round(self, args):
        if len(args) == 1:
            return f"ROUND({args[0]}, 0)"
        return f"ROUND({', '.join(args)})"

    def _convert_greatest(self, args):
        if len(args) >= 2:
            values = ", ".join(f"({a})" for a in args)
            return f"(SELECT MAX(v) FROM (VALUES{values}) AS T(v))"
        return args[0] if args else "NULL"

    def _convert_least(self, args):
        if len(args) >= 2:
            values = ", ".join(f"({a})" for a in args)
            return f"(SELECT MIN(v) FROM (VALUES{values}) AS T(v))"
        return args[0] if args else "NULL"
