"""Exception handling conversion: Oracle EXCEPTION → T-SQL TRY/CATCH.

Oracle pattern:
    BEGIN
        ... statements ...
    EXCEPTION
        WHEN exc1 THEN ...
        WHEN exc2 THEN ...
    END;

T-SQL pattern:
    BEGIN TRY
        ... statements ...
    END TRY
    BEGIN CATCH
        IF condition1 BEGIN ... END
        ELSE IF condition2 BEGIN ... END
    END CATCH
"""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG

# Oracle exception → MSSQL error check
EXCEPTION_MAP = {
    "NO_DATA_FOUND": "@@ROWCOUNT = 0",
    "TOO_MANY_ROWS": "ERROR_NUMBER() = 512",
    "DUP_VAL_ON_INDEX": "ERROR_NUMBER() IN (2601, 2627)",
    "ZERO_DIVIDE": "ERROR_NUMBER() = 8134",
    "VALUE_ERROR": "ERROR_NUMBER() = 245",
    "INVALID_NUMBER": "ERROR_NUMBER() = 245",
    "CURSOR_ALREADY_OPEN": "ERROR_NUMBER() = 16915",
    "INVALID_CURSOR": "ERROR_NUMBER() = 16916",
    "OTHERS": "1=1",
}


class ExceptionRule(ConversionRule):
    name = "exceptions"
    order = 35  # Must run BEFORE syntax rule (40) which converts END IF/END LOOP to END;

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = self._convert_all_exception_blocks(source, ctx)

        # SQLERRM → ERROR_MESSAGE()
        result = re.sub(r'\bSQLERRM\b', 'ERROR_MESSAGE()', result, flags=re.IGNORECASE)

        # SQLCODE → ERROR_NUMBER()
        result = re.sub(r'\bSQLCODE\b', 'ERROR_NUMBER()', result, flags=re.IGNORECASE)

        # RAISE; (re-raise) → THROW;
        result = re.sub(r'\bRAISE\s*;', 'THROW;', result, flags=re.IGNORECASE)

        # RAISE exception_name → THROW
        result = re.sub(
            r'\bRAISE\s+(\w+)\s*;',
            lambda m: f"THROW 50000, '{m.group(1).upper()}', 1;",
            result, flags=re.IGNORECASE
        )

        # After all exception conversion is done, check for T-SQL FUNCTION restrictions.
        # T-SQL scalar functions do not support TRY/CATCH.
        result = self._strip_try_catch_from_functions(result, ctx)

        return result

    def _strip_try_catch_from_functions(self, source: str, ctx: ConversionContext) -> str:
        """Strip TRY/CATCH from CREATE OR ALTER FUNCTION blocks."""
        batches = re.split(r'(^GO\s*$)', source, flags=re.MULTILINE | re.IGNORECASE)
        result_batches = []
        for batch in batches:
            if re.match(r'^GO\s*$', batch, re.IGNORECASE):
                result_batches.append(batch)
            elif re.search(r'CREATE\s+OR\s+ALTER\s+FUNCTION\b', batch, re.IGNORECASE):
                # It's a function block
                body = batch
                if re.search(r'\bBEGIN\s+TRY\b', body, re.IGNORECASE):
                    ctx.add_manual_review("Function: Exception handler removed (not supported in T-SQL function)")
                    
                    # Revert BEGIN TRY to BEGIN, remove END TRY completely (the END; is restored where END CATCH was)
                    body = re.sub(r'^(\s*)BEGIN\s+TRY\b.*$', r'\1BEGIN', body, flags=re.IGNORECASE | re.MULTILINE)
                    body = re.sub(r'^\s*END\s+TRY\b.*$', '', body, flags=re.IGNORECASE | re.MULTILINE)
                    
                    def replace_catch(m):
                        return f"/* {MANUAL_REVIEW_TAG} Exception handler removed. Original CATCH block stripped. */\nEND;"
                        
                    body = re.sub(
                        r'^\s*BEGIN\s+CATCH\b.*?^\s*END\s+CATCH\b',
                        replace_catch,
                        body,
                        flags=re.IGNORECASE | re.MULTILINE | re.DOTALL
                    )
                result_batches.append(body)
            else:
                result_batches.append(batch)
                
        return ''.join(result_batches)

    def _build_block_comment_lines(self, lines: list[str]) -> set[int]:
        """Return set of line indices that are inside /* */ block comments."""
        in_comment = False
        comment_lines = set()
        for i, line in enumerate(lines):
            if not in_comment:
                idx = line.find('/*')
                if idx >= 0:
                    close_idx = line.find('*/', idx + 2)
                    if close_idx < 0:
                        # Opened but not closed on this line
                        in_comment = True
                        comment_lines.add(i)
                    # else: opens and closes on same line — not a block comment line
            else:
                comment_lines.add(i)
                if '*/' in line:
                    in_comment = False
        return comment_lines

    def _convert_all_exception_blocks(self, source: str, ctx: ConversionContext) -> str:
        """Convert all BEGIN...EXCEPTION...END blocks to TRY/CATCH.

        Works by scanning for EXCEPTION keyword and finding matching BEGIN/END pairs.
        Processes from innermost blocks outward to handle nesting.
        """
        # Process iteratively until no more EXCEPTION keywords found
        result = source
        max_iterations = 200  # safety limit
        iteration = 0

        while iteration < max_iterations:
            iteration += 1

            # Find the last (innermost) EXCEPTION keyword NOT inside a block comment
            lines = result.split('\n')
            comment_lines = self._build_block_comment_lines(lines)
            exc_line_idx = None

            for i in range(len(lines) - 1, -1, -1):
                if i in comment_lines:
                    continue  # Skip lines inside /* */ block comments
                stripped = lines[i].strip().upper()
                if stripped.startswith('EXCEPTION'):
                    exc_line_idx = i
                    break

            if exc_line_idx is None:
                break  # No more EXCEPTION blocks

            # Find matching BEGIN (scan backwards, skipping comment lines)
            begin_idx = self._find_matching_begin(lines, exc_line_idx, comment_lines)

            # Find matching END (scan forward from EXCEPTION, skipping comment lines)
            end_idx = self._find_matching_end(lines, exc_line_idx, comment_lines)

            if begin_idx is None or end_idx is None:
                # Can't find matching BEGIN/END, comment out this EXCEPTION
                indent = self._get_indent(lines[exc_line_idx])
                lines[exc_line_idx] = f"{indent}/* {MANUAL_REVIEW_TAG} unmatched EXCEPTION */"
                result = '\n'.join(lines)
                continue

            # Extract the three sections
            indent = self._get_indent(lines[begin_idx])
            begin_line = lines[begin_idx]

            # Body: from BEGIN+1 to EXCEPTION-1
            body_lines = lines[begin_idx + 1:exc_line_idx]

            # Exception handlers: from EXCEPTION+1 to END-1
            handler_lines = lines[exc_line_idx + 1:end_idx]

            # Convert handlers
            catch_body = self._convert_handlers(handler_lines, ctx)

            # Build replacement
            new_lines = (
                lines[:begin_idx] +
                [f"{indent}BEGIN TRY"] +
                body_lines +
                [f"{indent}END TRY"] +
                [f"{indent}BEGIN CATCH"] +
                [catch_body] +
                [f"{indent}END CATCH"] +
                lines[end_idx + 1:]
            )

            result = '\n'.join(new_lines)

        return result

    @staticmethod
    def _is_block_end(stripped: str) -> bool:
        """Return True if this line is a block-level END (not inline CASE WHEN...END).

        Inline CASE expressions end with END) or END, etc.
        Block-level END is: END; | END | END TRY | END CATCH | END identifier;
        The key: block END is followed by ; , whitespace, an identifier, or nothing.
        It is NOT followed by ) , + - || or other expression characters.
        """
        if not re.match(r'END\b', stripped, re.IGNORECASE):
            return False
        # What follows END?
        rest = stripped[3:].lstrip()  # everything after 'END'
        # Empty (bare END at EOL) or starts with ; or word char → block END
        if not rest or rest[0] in (';', '\n', '\r') or re.match(r'\w', rest):
            return True
        return False

    @staticmethod
    def _is_block_begin(stripped: str) -> bool:
        """Return True if this line starts a block-level BEGIN."""
        return bool(re.match(r'BEGIN\b', stripped, re.IGNORECASE))

    def _find_matching_begin(self, lines: list[str], exc_idx: int,
                             comment_lines: set[int] | None = None) -> int | None:
        """Find the BEGIN that matches this EXCEPTION by counting nesting."""
        if comment_lines is None:
            comment_lines = set()
        depth = 0
        for i in range(exc_idx - 1, -1, -1):
            if i in comment_lines:
                continue  # Skip lines inside block comments
            stripped = lines[i].strip().upper()

            # Count END keywords (they increase depth when going backwards)
            # Skip END IF, END LOOP, END CASE — only count block-level END
            # Also skip inline END) from CASE WHEN expressions
            if (self._is_block_end(stripped) and
                    not re.match(r'END\s+(IF|LOOP|CASE)\b', stripped, re.IGNORECASE)):
                depth += 1
            elif self._is_block_begin(stripped):
                if depth == 0:
                    return i
                depth -= 1

        return None

    def _find_matching_end(self, lines: list[str], exc_idx: int,
                           comment_lines: set[int] | None = None) -> int | None:
        """Find the END that closes this EXCEPTION block."""
        if comment_lines is None:
            comment_lines = set()
        # The END is at the same nesting level as the EXCEPTION
        depth = 0
        for i in range(exc_idx + 1, len(lines)):
            if i in comment_lines:
                continue  # Skip lines inside block comments
            stripped = lines[i].strip().upper()

            if self._is_block_begin(stripped):
                depth += 1
            elif (self._is_block_end(stripped) and
                  not re.match(r'END\s+(IF|LOOP|CASE)\b', stripped, re.IGNORECASE)):
                if depth == 0:
                    return i
                depth -= 1

        return None

    def _convert_handlers(self, handler_lines: list[str], ctx: ConversionContext) -> str:
        """Convert WHEN exception THEN ... blocks to IF/ELSE IF."""
        text = '\n'.join(handler_lines)

        # Split by WHEN keyword
        when_pattern = re.compile(
            r'\bWHEN\s+(\w+)\s+THEN\b',
            re.IGNORECASE
        )

        parts = when_pattern.split(text)
        # parts[0] is before first WHEN (usually empty)
        # parts[1] is exception name, parts[2] is handler body, etc.

        if len(parts) < 3:
            # Simple: just return the handler code as-is
            return text

        result_parts = []
        first = True
        i = 1
        while i < len(parts) - 1:
            exc_name = parts[i].strip().upper()
            handler_body = parts[i + 1].strip()

            # Remove trailing handler code that belongs to next WHEN
            condition = EXCEPTION_MAP.get(exc_name)
            if condition is None:
                condition = f"1=1 /* {MANUAL_REVIEW_TAG} unknown: {exc_name} */"
                ctx.add_manual_review(f"Unknown exception: {exc_name}")

            if exc_name == "OTHERS":
                result_parts.append(f"        -- WHEN OTHERS\n        {handler_body}")
            elif first:
                result_parts.append(f"        IF {condition}\n        BEGIN\n            {handler_body}\n        END")
                first = False
            else:
                result_parts.append(f"        ELSE IF {condition}\n        BEGIN\n            {handler_body}\n        END")

            i += 2

        return '\n'.join(result_parts) if result_parts else "        -- No handlers"

    def _get_indent(self, line: str) -> str:
        """Extract leading whitespace from a line."""
        return line[:len(line) - len(line.lstrip())]
