"""Cursor conversion rules: explicit cursors, BULK COLLECT, FORALL."""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


class CursorRule(ConversionRule):
    name = "cursors"
    order = 50

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = source

        # CURSOR declaration: CURSOR name IS [comments...] SELECT/WITH → DECLARE name CURSOR FOR SELECT/WITH
        # Handle IS followed by optional comment lines before SELECT or WITH
        result = re.sub(
            r'\bCURSOR\s+(\w+)\s+IS\s*(?:\s*--[^\n]*\n)*\s*((?:SELECT|WITH)\b)',
            r'DECLARE \1 CURSOR LOCAL FAST_FORWARD FOR \2',
            result, flags=re.IGNORECASE
        )

        # Parameterized cursor: CURSOR name(params) IS [comments...] SELECT/WITH
        # Use nested-paren-aware capture for params (handles NVARCHAR(4000) etc.)
        result = re.sub(
            r'\bCURSOR\s+(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)\s+IS\s*(?:\s*--[^\n]*\n)*\s*((?:SELECT|WITH)\b)',
            lambda m: self._convert_parameterized_cursor(m, ctx),
            result, flags=re.IGNORECASE
        )

        # Remove any /*INTO ...*/ blocks that might have been manually or tool-generated
        # inside CURSOR's SELECT declarations, as they cause parser errors in T-SQL.
        # We can safely strip this pattern globally since /*INTO...*/ has no meaning in T-SQL.
        result = re.sub(r'/\*INTO.+?\*/', '', result, flags=re.IGNORECASE | re.DOTALL)

        # Handle cases where INTO might be on the same line as a comment
        result = re.sub(
            r'(--[^\n]*)\s*\bINTO\b',
            r'\1\nINTO',
            result, flags=re.IGNORECASE
        )


        # OPEN cursor → OPEN cursor
        # (same syntax, but need to handle parameterized cursor)
        result = re.sub(
            r'\bOPEN\s+(\w+)\s*\(([^)]+)\)\s*;',
            lambda m: self._convert_cursor_open_params(m, ctx),
            result, flags=re.IGNORECASE
        )

        # FETCH cursor INTO vars → FETCH NEXT FROM cursor INTO @vars
        # Allow optional comment lines between FETCH cursor and INTO
        result = re.sub(
            r'\bFETCH\s+(\w+)\s*(?:\n\s*--[^\n]*)*\s+INTO\s+',
            r'FETCH NEXT FROM \1 INTO ',
            result, flags=re.IGNORECASE
        )

        # EXIT WHEN cursor%NOTFOUND → IF @@FETCH_STATUS <> 0 BREAK
        result = re.sub(
            r'\bIF\s+\w+%NOTFOUND\b.*?BREAK\s*;',
            'IF @@FETCH_STATUS <> 0 BREAK;',
            result, flags=re.IGNORECASE
        )
        result = re.sub(
            r'\bEXIT\s+WHEN\s+\w+%NOTFOUND\s*;',
            'IF @@FETCH_STATUS <> 0 BREAK;',
            result, flags=re.IGNORECASE
        )

        # cursor%FOUND → @@FETCH_STATUS = 0
        result = re.sub(r'\b\w+%FOUND\b', '@@FETCH_STATUS = 0', result, flags=re.IGNORECASE)

        # cursor%NOTFOUND → @@FETCH_STATUS <> 0
        result = re.sub(r'\b\w+%NOTFOUND\b', '@@FETCH_STATUS <> 0', result, flags=re.IGNORECASE)

        # cursor%ROWCOUNT → @@ROWCOUNT
        result = re.sub(r'\b\w+%ROWCOUNT\b', '@@ROWCOUNT', result, flags=re.IGNORECASE)

        # cursor%ISOPEN → CURSOR_STATUS('local', 'cursor_name') >= 0
        result = re.sub(
            r'\b(\w+)%ISOPEN\b',
            r"CURSOR_STATUS('local', '\1') >= 0",
            result, flags=re.IGNORECASE
        )

        # SQL%ROWCOUNT → @@ROWCOUNT
        result = re.sub(r'\bSQL%ROWCOUNT\b', '@@ROWCOUNT', result, flags=re.IGNORECASE)

        # SQL%FOUND → @@ROWCOUNT > 0
        result = re.sub(r'\bSQL%FOUND\b', '@@ROWCOUNT > 0', result, flags=re.IGNORECASE)

        # SQL%NOTFOUND → @@ROWCOUNT = 0
        result = re.sub(r'\bSQL%NOTFOUND\b', '@@ROWCOUNT = 0', result, flags=re.IGNORECASE)

        # BULK COLLECT INTO → flag + temp table pattern
        result = self._convert_bulk_collect(result, ctx)

        # FORALL → set-based operation flag
        result = self._convert_forall(result, ctx)

        # SYS_REFCURSOR → flag for review
        if re.search(r'\bSYS_REFCURSOR\b', result, re.IGNORECASE):
            ctx.add_manual_review("SYS_REFCURSOR - convert to result set or temp table")

        # CLOSE cursor → CLOSE cursor; DEALLOCATE cursor
        result = re.sub(
            r'\bCLOSE\s+(\w+)\s*;',
            r'CLOSE \1;\nDEALLOCATE \1;',
            result, flags=re.IGNORECASE
        )

        return result

    def _convert_parameterized_cursor(self, m, ctx: ConversionContext) -> str:
        """Convert parameterized cursor - params become local variables."""
        name = m.group(1)
        params = m.group(2)
        select = m.group(3)
        ctx.add_manual_review(
            f"Parameterized cursor '{name}' - set @variables before OPEN"
        )
        return f"/* Params: {params} - set before OPEN */\nDECLARE {name} CURSOR LOCAL FAST_FORWARD FOR {select}"

    def _convert_cursor_open_params(self, m, ctx: ConversionContext) -> str:
        """Convert OPEN cursor(params) → SET vars + OPEN cursor."""
        name = m.group(1)
        params = m.group(2)
        return f"/* Set cursor params: {params} */\nOPEN {name};"

    def _convert_bulk_collect(self, source: str, ctx: ConversionContext) -> str:
        """Convert BULK COLLECT INTO to temp table pattern."""
        pattern = re.compile(
            r'\bBULK\s+COLLECT\s+INTO\s+(\w+)',
            re.IGNORECASE
        )

        def replace_bulk(m):
            var_name = m.group(1)
            ctx.add_manual_review(
                f"BULK COLLECT INTO {var_name} → INSERT INTO #temp SELECT or table variable"
            )
            return f"/* {MANUAL_REVIEW_TAG} BULK COLLECT → INSERT INTO #{var_name} */ INTO #{var_name}"

        return pattern.sub(replace_bulk, source)

    def _convert_forall(self, source: str, ctx: ConversionContext) -> str:
        """Convert FORALL to set-based operations."""
        pattern = re.compile(
            r'\bFORALL\s+(\w+)\s+IN\s+(.+?)\n\s*(INSERT|UPDATE|DELETE|MERGE)\b',
            re.IGNORECASE
        )

        def replace_forall(m):
            idx_var = m.group(1)
            range_expr = m.group(2)
            dml = m.group(3)
            ctx.add_manual_review(
                f"FORALL {idx_var} → convert to set-based {dml} operation"
            )
            return (
                f"/* {MANUAL_REVIEW_TAG} FORALL → set-based operation */\n"
                f"/* Original range: {range_expr} */\n"
                f"{dml}"
            )

        return pattern.sub(replace_forall, source)
