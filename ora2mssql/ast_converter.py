"""
AST-based Oracle PL/SQL → MSSQL T-SQL conversion engine.

Replaces the regex-based converter with an ANTLR4 parse tree approach.
Uses TokenStreamRewriter for precise token-level transforms + text post-processing.
"""
from __future__ import annotations
import json
import logging
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from antlr4 import CommonTokenStream, InputStream, TokenStreamRewriter
from antlr4.error.ErrorListener import ErrorListener

from .config import AppConfig
from .converter import ConversionResult
from .extractor import load_manifest
from .utils import ensure_dir, write_file, read_file

logger = logging.getLogger("ora2mssql")


class _SilentErrorListener(ErrorListener):
    """Suppress ANTLR4 parse error console output; collect them instead."""
    def __init__(self):
        super().__init__()
        self.errors: list[str] = []

    def syntaxError(self, recognizer, offendingSymbol, line, column, msg, e):
        self.errors.append(f"line {line}:{column} {msg}")


def _parse_plsql(source: str):
    """Parse Oracle PL/SQL source. Returns (parser, token_stream, error_count, errors)."""
    from ora2mssql.parser.PlSqlLexer import PlSqlLexer
    from ora2mssql.parser.PlSqlParser import PlSqlParser

    # Ensure source ends with newline (grammar expects it)
    if not source.endswith('\n'):
        source += '\n'

    input_stream = InputStream(source)
    lexer = PlSqlLexer(input_stream)
    err_listener = _SilentErrorListener()
    lexer.removeErrorListeners()
    lexer.addErrorListener(err_listener)

    token_stream = CommonTokenStream(lexer)
    parser = PlSqlParser(token_stream)
    parser.removeErrorListeners()
    parser.addErrorListener(err_listener)

    tree = parser.sql_script()
    return parser, token_stream, tree, err_listener.errors


# ---------------------------------------------------------------------------
# Header builder: creates the CREATE OR ALTER PROCEDURE/FUNCTION header
# ---------------------------------------------------------------------------

def _build_routine_header(
    schema: str,
    name: str,
    is_function: bool,
    params_text: str,
    return_type: Optional[str] = None,
) -> str:
    """Build the T-SQL CREATE OR ALTER header for a procedure or function."""
    kind = "FUNCTION" if is_function else "PROCEDURE"
    header = f"CREATE OR ALTER {kind} [{schema}].[{name}]"
    if params_text.strip():
        header += f"\n({params_text}\n)"
    else:
        header += "\n()"
    if is_function and return_type:
        from .ast_visitors.type_mapper import map_type
        mssql_return = map_type(return_type)
        header += f"\nRETURNS {mssql_return}"
    header += "\nAS"
    return header


# ---------------------------------------------------------------------------
# Parameter transformer
# ---------------------------------------------------------------------------

def _transform_params(params_text: str) -> str:
    """
    Convert Oracle parameter list to T-SQL.

    Oracle: p_name IN VARCHAR2, p_out OUT NUMBER
    T-SQL:  @p_name NVARCHAR(MAX), @p_out DECIMAL(38,10) OUTPUT
    """
    from .ast_visitors.type_mapper import map_type

    if not params_text.strip():
        return ""

    result_params = []
    # Split on commas that are NOT inside parentheses
    parts = _split_params(params_text)

    for part in parts:
        part = part.strip()
        if not part:
            continue

        # Match: name [IN|OUT|IN OUT] type [DEFAULT expr | := expr]
        # Oracle allows: p1 IN VARCHAR2 DEFAULT NULL, p2 OUT NUMBER
        m = re.match(
            r'(\w+)\s+(IN\s+OUT|IN/OUT|IN|OUT|INOUT)?\s*(.*?)(?:\s+DEFAULT\s+(.+)|\s*:=\s*(.+))?$',
            part, re.IGNORECASE | re.DOTALL
        )
        if not m:
            result_params.append(f"    @{part}")
            continue

        p_name = m.group(1)
        direction = (m.group(2) or "IN").strip().upper()
        type_part = (m.group(3) or "").strip()
        default_val = m.group(4) or m.group(5)

        # Remove DEFAULT/':=' from type_part if regex didn't capture it
        type_part = re.split(r'\s+DEFAULT\b|\s*:=', type_part, flags=re.IGNORECASE)[0].strip()

        mssql_type = map_type(type_part) if type_part else "NVARCHAR(MAX)"

        param_str = f"    @{p_name} {mssql_type}"
        if direction in ("OUT", "IN OUT", "IN/OUT", "INOUT"):
            param_str += " OUTPUT"
        if default_val:
            dv = _transform_default(default_val.strip())
            param_str += f" = {dv}"

        result_params.append(param_str)

    return ",\n".join(result_params)


def _transform_default(val: str) -> str:
    """Convert Oracle default value to T-SQL."""
    v = val.strip().rstrip(";")
    v = re.sub(r'\bNULL\b', 'NULL', v, flags=re.IGNORECASE)
    v = re.sub(r'\bSYSDATE\b', 'GETDATE()', v, flags=re.IGNORECASE)
    v = re.sub(r'\bTRUE\b', '1', v, flags=re.IGNORECASE)
    v = re.sub(r'\bFALSE\b', '0', v, flags=re.IGNORECASE)
    return v


def _split_params(text: str) -> list[str]:
    """Split parameter list on commas, respecting nested parentheses."""
    parts = []
    depth = 0
    current = []
    for ch in text:
        if ch == '(':
            depth += 1
            current.append(ch)
        elif ch == ')':
            depth -= 1
            current.append(ch)
        elif ch == ',' and depth == 0:
            parts.append(''.join(current).strip())
            current = []
        else:
            current.append(ch)
    if current:
        parts.append(''.join(current).strip())
    return parts


# ---------------------------------------------------------------------------
# AST-based routine body transformer
# ---------------------------------------------------------------------------

class RoutineBodyTransformer:
    """
    Transforms the body of a single procedure/function from Oracle PL/SQL
    to MSSQL T-SQL using ANTLR4 + text-level transforms.
    """

    def __init__(self, token_stream, tokens: list, pkg_name: str, param_names: set[str]):
        self.token_stream = token_stream
        self.tokens = tokens
        self.pkg_name = pkg_name
        self.param_names = param_names  # for @ prefix

    def transform(self, routine_ctx, raw_source: str) -> str:
        """
        Extract the body source text and apply transformations.

        Returns T-SQL body (from AS/BEGIN to END).
        """
        from .ast_visitors.declaration_collector import DeclarationCollector
        from .ast_visitors.syntax_transformer import SyntaxTransformer

        # Collect declarations from parse tree
        collector = DeclarationCollector()
        decls = collector.collect(routine_ctx)

        # Get declare section and body text
        declare_text, body_text = self._split_declare_body(raw_source)

        # Build DECLARE block for T-SQL
        declare_block = self._build_declare_block(decls, declare_text)

        # Transform body
        transformer = SyntaxTransformer(
            tokens=self.tokens,
            stream=self.token_stream,
            pkg_name=self.pkg_name,
            routine_name="",
            all_vars={d.name.upper() for d in decls},
            all_params=self.param_names,
        )
        body_tsql = transformer._post_process(body_text, decls, routine_ctx)
        body_tsql = self._add_var_prefix(body_tsql, decls)

        # Assemble
        parts = []
        if declare_block.strip():
            parts.append(declare_block)
        parts.append("BEGIN")
        parts.append(body_tsql)
        parts.append("END")

        return "\n".join(parts)

    def _split_declare_body(self, source: str) -> tuple[str, str]:
        """
        Split an Oracle routine into (declare_section, body_section).

        Oracle structure:
            [declare vars/cursors]
            BEGIN
                statements
            END;

        Returns (declare_text, body_text) where body_text includes BEGIN/END.
        """
        # Find the first standalone BEGIN
        lines = source.split('\n')
        begin_idx = None
        depth = 0
        in_comment = False

        for i, line in enumerate(lines):
            stripped = line.strip().upper()
            # Track block comments
            if '/*' in stripped:
                in_comment = True
            if '*/' in stripped:
                in_comment = False
            if in_comment:
                continue
            # Strip line comments
            stripped = re.sub(r'--.*$', '', stripped).strip()

            if re.match(r'^BEGIN\b', stripped):
                begin_idx = i
                break

        if begin_idx is None:
            return "", source

        declare_text = '\n'.join(lines[:begin_idx])
        body_text = '\n'.join(lines[begin_idx:])
        return declare_text, body_text

    def _build_declare_block(self, decls, declare_text: str) -> str:
        """Build DECLARE block from collected declarations."""
        from .ast_visitors.type_mapper import map_type

        if not decls:
            return ""

        declare_lines = ["DECLARE"]
        for d in decls:
            if d.is_cursor:
                # Cursors: declare as CURSOR variable
                declare_lines.append(f"    {d.name} CURSOR FOR")
                if d.cursor_query:
                    declare_lines.append(f"        {d.cursor_query}")
            elif d.is_exception:
                declare_lines.append(f"    @{d.name} INT = 0  -- exception flag")
            else:
                mssql_type = d.mssql_type
                line = f"    @{d.name} {mssql_type}"
                if d.default_value:
                    dv = _transform_default(d.default_value)
                    line += f" = {dv}"
                declare_lines.append(line)

        return '\n'.join(declare_lines)

    def _add_var_prefix(self, body: str, decls) -> str:
        """Add @ prefix to local variable references in body."""
        # Build set of all local var names
        var_names = {d.name for d in decls if not d.is_cursor}
        var_names.update(self.param_names)

        # Add @ prefix to variable references (word boundary match)
        for var in sorted(var_names, key=len, reverse=True):
            # Don't double-prefix
            pattern = r'(?<!\w)(?<!@)' + re.escape(var) + r'(?!\w)'
            body = re.sub(pattern, f'@{var}', body, flags=re.IGNORECASE)

        return body


# ---------------------------------------------------------------------------
# Main AST converter class
# ---------------------------------------------------------------------------

class AstConverter:
    """
    ANTLR4-based converter for Oracle Package Bodies → MSSQL T-SQL stored procedures.
    """

    def convert_package_body(
        self,
        source: str,
        pkg_name: str,
        schema: str,
        output_dir: Path,
    ) -> list[ConversionResult]:
        """
        Convert an Oracle Package Body source to T-SQL.

        Returns list of ConversionResult (one per procedure/function).
        """
        results = []

        # Step 1: Add CREATE OR REPLACE wrapper if missing
        wrapped = self._wrap_source(source, pkg_name)

        # Step 2: Parse with ANTLR4
        logger.info(f"[AST] Parsing {pkg_name} ...")
        try:
            parser, token_stream, tree, errors = _parse_plsql(wrapped)
        except Exception as e:
            logger.error(f"[AST] Parse failed for {pkg_name}: {e}")
            return results

        if errors:
            logger.warning(f"[AST] {len(errors)} parse errors in {pkg_name}: {errors[:3]}")

        # Step 3: Split package into routines
        from .ast_visitors.package_splitter import PackageSplitter
        splitter = PackageSplitter(token_stream)

        try:
            routines = splitter.split(tree)
        except Exception as e:
            logger.error(f"[AST] Package split failed for {pkg_name}: {e}")
            return results

        logger.info(f"[AST] Found {len(routines)} routines in {pkg_name}")

        # Step 4: Get all tokens as list
        token_stream.fill()
        all_tokens = token_stream.tokens  # list of Token objects

        # Step 5: Convert each routine
        for routine in routines:
            try:
                result = self._convert_routine(
                    routine=routine,
                    token_stream=token_stream,
                    all_tokens=all_tokens,
                    schema=schema,
                    pkg_name=pkg_name,
                    wrapped_source=wrapped,
                )
                results.append(result)

                # Write output
                out_path = ensure_dir(output_dir / schema) / f"{pkg_name}__{routine.name}.sql"
                write_file(out_path, result.tsql)
                logger.info(f"[AST] Converted {schema}.{routine.name} → {out_path}")
            except Exception as e:
                logger.error(f"[AST] Failed to convert {routine.name}: {e}", exc_info=True)
                results.append(ConversionResult(
                    source_name=f"{pkg_name}.{routine.name}",
                    source_type="FUNCTION" if routine.is_function else "PROCEDURE",
                    target_schema=schema,
                    target_name=routine.name,
                    tsql=f"-- CONVERSION FAILED: {e}\n",
                    warnings=[str(e)],
                    success=False,
                ))

        return results

    def _wrap_source(self, source: str, pkg_name: str) -> str:
        """Add CREATE OR REPLACE PACKAGE BODY wrapper if needed."""
        s = source.strip()
        # Already has CREATE OR REPLACE
        if re.match(r'CREATE\s+(OR\s+REPLACE\s+)?PACKAGE\s+BODY', s, re.IGNORECASE):
            if not s.endswith('/'):
                s += '\n/'
            return s
        # Starts with PACKAGE BODY
        if re.match(r'PACKAGE\s+BODY', s, re.IGNORECASE):
            s = f"CREATE OR REPLACE {s}"
            if not s.endswith('/'):
                s += '\n/'
            return s
        # Bare body (starts with PROCEDURE or comment)
        return f"CREATE OR REPLACE PACKAGE BODY {pkg_name} IS\n{s}\nEND {pkg_name};\n/"

    def _convert_routine(
        self,
        routine,
        token_stream,
        all_tokens: list,
        schema: str,
        pkg_name: str,
        wrapped_source: str,
    ) -> ConversionResult:
        """Convert a single routine to T-SQL."""
        from .ast_visitors.type_mapper import map_type

        # Extract raw source text for this routine
        start_idx = routine.start_token_index
        stop_idx = routine.stop_token_index
        raw_parts = []
        for tok in all_tokens[start_idx:stop_idx + 1]:
            if tok.type != -1:  # -1 is EOF
                raw_parts.append(tok.text)
        routine_source = ''.join(raw_parts)

        # Build parameter string
        param_names = {p[0].upper() for p in routine.params}
        params_tsql = _transform_params(
            ', '.join(f"{p[0]} {p[1]} {p[2]}" for p in routine.params)
        )

        # Build T-SQL header
        header = _build_routine_header(
            schema=schema,
            name=routine.name,
            is_function=routine.is_function,
            params_text=params_tsql,
            return_type=routine.return_type if routine.is_function else None,
        )

        # Transform the body
        body_transformer = RoutineBodyTransformer(
            token_stream=token_stream,
            tokens=all_tokens,
            pkg_name=pkg_name,
            param_names=param_names,
        )

        # Find the routine context in the tree for declaration collection
        # For now, use text-based transformation with the post-processor
        from .ast_visitors.syntax_transformer import SyntaxTransformer
        transformer = SyntaxTransformer(
            tokens=all_tokens,
            stream=token_stream,
            pkg_name=pkg_name,
            routine_name=routine.name,
            all_vars=set(),
            all_params=param_names,
        )

        # Apply transformations to the routine body text
        body_tsql = self._transform_body_text(routine_source, transformer, param_names)

        # Combine header + body
        tsql = f"{header}\n{body_tsql}\nGO\n"

        # Final cleanup
        tsql = self._final_cleanup(tsql, schema, pkg_name)

        warnings: list[str] = []
        manual_review: list[str] = []
        if "/*TODO" in tsql or "TODO:" in tsql:
            manual_review.append("Contains TODO items requiring manual review")
        if "/*DECODE" in tsql:
            manual_review.append("DECODE function requires manual conversion")

        return ConversionResult(
            source_name=f"{pkg_name}.{routine.name}",
            source_type="FUNCTION" if routine.is_function else "PROCEDURE",
            target_schema=schema,
            target_name=routine.name,
            tsql=tsql,
            warnings=warnings,
            manual_review=manual_review,
            success=True,
        )

    def _transform_body_text(
        self,
        source: str,
        transformer: "SyntaxTransformer",
        param_names: set[str],
    ) -> str:
        """Apply all text-level transformations to a routine's source text."""

        # 1. Split off the declare section (before first BEGIN)
        declare_text, body_text = self._split_declare_body(source)

        # 2. Parse declarations from text
        decls = self._parse_declarations_from_text(declare_text)

        # 3. Build DECLARE block (separate DECLARE per item)
        declare_block = self._build_declare_block_text(decls, param_names)

        # 4. body_text starts with BEGIN; strip inner content for transformation
        body_only = self._strip_routine_header(body_text)
        # body_only = "BEGIN\n  ...\nEND name;"
        # Strip outer BEGIN/END to get inner statements
        inner_body = self._strip_begin_end(body_only)

        # 5. Apply built-in function transforms
        transformed = transformer._convert_functions(inner_body)

        # 6. Fix boolean literals
        transformed = transformer._fix_boolean(transformed)

        # 7. Convert string concatenation
        transformed = transformed.replace('||', '+')

        # 8. Convert EXCEPTION/WHEN → TRY/CATCH FIRST
        # (must be before _fix_if_structure which converts THEN → BEGIN)
        transformed = self._convert_exception_block(transformed)

        # 9. Convert := assignments → SET @var = ...
        all_var_names = {d['name'] for d in decls} | param_names
        transformed = self._convert_assignments(transformed, all_var_names)

        # 10. Add @ prefix to variables (after assignment conversion)
        transformed = self._add_var_prefix(transformed, all_var_names)

        # 11. Fix IF/THEN/ELSIF/END IF structure
        transformed = self._fix_if_structure(transformed)

        # 12. Fix LOOP / FOR LOOP / WHILE LOOP structure
        transformed = self._fix_loop_structure(transformed)

        # 13. Reassemble with DECLARE + BEGIN...END
        if declare_block.strip():
            result = f"{declare_block}\nBEGIN\n{transformed}\nEND"
        else:
            result = f"BEGIN\n{transformed}\nEND"

        return result

    def _strip_begin_end(self, body_text: str) -> str:
        """Remove outer BEGIN...END from body text, preserving inner content."""
        stripped = body_text.strip()
        # Remove leading BEGIN
        if re.match(r'^BEGIN\b', stripped, re.IGNORECASE):
            stripped = stripped[5:].lstrip('\n')
        # Remove trailing END name; or END;
        stripped = re.sub(r'\bEND\s+\w+\s*;\s*$', '', stripped.rstrip(), flags=re.IGNORECASE)
        stripped = re.sub(r'\bEND\s*;\s*$', '', stripped.rstrip(), flags=re.IGNORECASE)
        stripped = re.sub(r'\bEND\s*$', '', stripped.rstrip(), flags=re.IGNORECASE)
        return stripped

    def _convert_assignments(self, body: str, var_names: set[str]) -> str:
        """Convert Oracle := assignments to T-SQL SET @var = ..."""
        # Convert: varname := expression; → SET @varname = expression;
        # Must handle multiline expressions and nested parens
        def replace_assign(m):
            varname = m.group(1)
            expr = m.group(2).strip()
            # If already prefixed with @, don't double
            if varname.startswith('@'):
                return f"SET {varname} = {expr};"
            return f"SET @{varname} = {expr};"

        result = re.sub(
            r'(?<![<>!:])(\w+)\s*:=\s*((?:[^;\'"]|\'[^\']*\'|"[^"]*")*?);',
            replace_assign,
            body,
            flags=re.IGNORECASE | re.DOTALL
        )
        return result

    def _convert_exception_block(self, body: str) -> str:
        """
        Convert Oracle BEGIN...EXCEPTION...END → T-SQL BEGIN TRY...END TRY BEGIN CATCH...END CATCH.

        Handles both:
          - Inner BEGIN...EXCEPTION...END blocks (inline)
          - Bare EXCEPTION...WHEN at outer level
        """
        # Pattern: BEGIN <body> EXCEPTION <when_clauses> END
        # Handle with a loop to support multiple exception blocks
        result = body
        max_iterations = 20
        iteration = 0

        while iteration < max_iterations:
            iteration += 1
            # Find EXCEPTION keyword
            exc_m = re.search(r'\bEXCEPTION\b', result, re.IGNORECASE)
            if not exc_m:
                break

            exc_pos = exc_m.start()
            before_exc = result[:exc_pos]
            after_exc = result[exc_pos + len('EXCEPTION'):]

            # Find the matching BEGIN for this EXCEPTION block
            # Walk backwards through before_exc counting BEGIN/END depth
            begin_pos = self._find_matching_begin_pos(before_exc)

            # Find the END that closes this exception block
            end_pos, end_len = self._find_closing_end(after_exc)

            if begin_pos is not None and end_pos is not None:
                # Convert: text_before + BEGIN + try_body + EXCEPTION + when_text + END + text_after
                text_before = before_exc[:begin_pos]
                try_body = before_exc[begin_pos + 5:].strip()  # skip BEGIN\n
                when_text = after_exc[:end_pos]
                text_after = after_exc[end_pos + end_len:]

                catch_body = self._parse_when_clauses(when_text)

                try_block = (
                    f"BEGIN TRY\n    {try_body}\nEND TRY\n"
                    f"BEGIN CATCH\n{catch_body}\nEND CATCH"
                )
                result = text_before + try_block + text_after
            elif begin_pos is None:
                # No matching BEGIN — bare EXCEPTION (outer procedure level)
                when_text = after_exc
                # Remove trailing END; if present
                when_text = re.sub(r'\bEND\s*;?\s*$', '', when_text, flags=re.IGNORECASE).rstrip()
                catch_body = self._parse_when_clauses(when_text)
                result = before_exc.rstrip() + f"\nEND TRY\nBEGIN CATCH\n{catch_body}\nEND CATCH"
                break
            else:
                # end_pos not found — break to avoid infinite loop
                result = (before_exc + "\nEND TRY\nBEGIN CATCH\n" +
                          self._parse_when_clauses(after_exc) + "\nEND CATCH")
                break

        return result

    def _find_matching_begin_pos(self, text: str) -> Optional[int]:
        """Find the position of the last unmatched BEGIN keyword in text."""
        # Walk through text tracking BEGIN/END depth
        # Returns position of the BEGIN that would match a following EXCEPTION
        tokens_re = re.compile(r'\b(BEGIN|END)\b', re.IGNORECASE)
        positions = []
        depth = 0

        # Walk forward, tracking BEGIN positions
        begin_stack = []
        for m in tokens_re.finditer(text):
            kw = m.group(1).upper()
            if kw == 'BEGIN':
                begin_stack.append(m.start())
            elif kw == 'END' and begin_stack:
                begin_stack.pop()

        if begin_stack:
            return begin_stack[-1]  # Last unmatched BEGIN
        return None

    def _find_closing_end(self, text: str) -> tuple[Optional[int], int]:
        """Find the first END keyword at depth 0 in text after EXCEPTION."""
        depth = 0
        tokens_re = re.compile(r'\b(BEGIN|END)\b', re.IGNORECASE)
        for m in tokens_re.finditer(text):
            kw = m.group(1).upper()
            if kw == 'BEGIN':
                depth += 1
            elif kw == 'END':
                if depth == 0:
                    # Check if followed by semicolon
                    end_len = m.end() - m.start()
                    # Skip 'END name;' or 'END;'
                    rest = text[m.end():].lstrip()
                    if rest.startswith(';'):
                        return m.start(), end_len + 1 + (len(text[m.end():]) - len(rest))
                    elif re.match(r'\w+\s*;', rest):
                        # END name;
                        semi = rest.index(';')
                        return m.start(), m.end() - m.start() + (len(text[m.end():]) - len(rest)) + semi + 1
                    return m.start(), end_len
                depth -= 1
        return None, 0

    def _parse_when_clauses(self, text: str) -> str:
        """Convert WHEN condition THEN handler → T-SQL CATCH body."""
        result_parts = []
        # Remove trailing END; artifacts
        text = re.sub(r'\bEND\s*;?\s*$', '', text.strip(), flags=re.IGNORECASE)

        # Split on WHEN keyword
        segments = re.split(r'\bWHEN\b', text, flags=re.IGNORECASE)

        for seg in segments:
            seg = seg.strip()
            if not seg:
                continue
            # Match: condition THEN handler
            m = re.match(r'(.+?)\s+THEN\b(.*)', seg, re.IGNORECASE | re.DOTALL)
            if not m:
                if seg:
                    result_parts.append(f"    {seg}")
                continue

            condition = m.group(1).strip().upper()
            handler = m.group(2).strip()

            if condition == "NO_DATA_FOUND":
                result_parts.append(
                    f"    IF ERROR_NUMBER() IN (1403, 100) BEGIN\n        {handler}\n    END"
                )
            elif condition == "DUP_VAL_ON_INDEX":
                result_parts.append(
                    f"    IF ERROR_NUMBER() = 2627 BEGIN\n        {handler}\n    END"
                )
            elif condition == "OTHERS":
                result_parts.append(f"    -- WHEN OTHERS\n    {handler}")
            else:
                result_parts.append(f"    -- WHEN {condition}\n    {handler}")

        return '\n'.join(result_parts)

    def _split_declare_body(self, source: str) -> tuple[str, str]:
        """Split Oracle routine source into (declare_section, begin_to_end)."""
        # Remove the procedure/function signature first
        # Find the first standalone BEGIN (not in a comment or string)
        lines = source.split('\n')
        begin_line = None
        in_header = True  # skip until we're past IS/AS

        # Find IS/AS (end of header)
        header_end = 0
        for i, line in enumerate(lines):
            stripped = re.sub(r'--.*$', '', line).strip().upper()
            if re.match(r'^(IS|AS)\s*$', stripped) or re.search(r'\bAS\s*$', stripped) or re.search(r'\bIS\s*$', stripped):
                header_end = i + 1
                break
            if i > 50:  # give up looking for IS/AS
                break

        # Now find BEGIN in the declare section
        for i in range(header_end, len(lines)):
            stripped = re.sub(r'--.*$', '', lines[i]).strip().upper()
            if re.match(r'^BEGIN\b', stripped):
                begin_line = i
                break

        if begin_line is None:
            return "", source

        declare_text = '\n'.join(lines[header_end:begin_line])
        body_text = '\n'.join(lines[begin_line:])
        return declare_text, body_text

    def _parse_declarations_from_text(self, declare_text: str) -> list[dict]:
        """Parse variable declarations from text using regex (fallback)."""
        from .ast_visitors.type_mapper import map_type
        decls = []

        # Remove comments
        text = re.sub(r'--[^\n]*', '', declare_text)
        text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)

        # Match variable declarations: name type [:= default] ;
        # Also handle CURSOR ... IS SELECT...
        cursor_pattern = re.compile(
            r'CURSOR\s+(\w+)\s+IS\s+(SELECT[^;]+);',
            re.IGNORECASE | re.DOTALL
        )
        for m in cursor_pattern.finditer(text):
            decls.append({
                'name': m.group(1),
                'oracle_type': 'CURSOR',
                'mssql_type': 'CURSOR',
                'default': None,
                'is_cursor': True,
                'cursor_query': m.group(2).strip(),
            })

        # Exception declarations: name EXCEPTION ;
        exc_pattern = re.compile(r'(\w+)\s+EXCEPTION\s*;', re.IGNORECASE)
        for m in exc_pattern.finditer(text):
            decls.append({
                'name': m.group(1),
                'oracle_type': 'EXCEPTION',
                'mssql_type': 'INT',
                'default': '0',
                'is_cursor': False,
                'is_exception': True,
            })

        # Variable declarations
        # Match: name type(:=expr)? ;
        # Type can include parentheses: VARCHAR2(100), NUMBER(10,2)
        var_pattern = re.compile(
            r'(\w+)\s+'
            r'((?:N?VARCHAR2|NCHAR|CHAR|NUMBER|DECIMAL|INTEGER|INT|SMALLINT|BIGINT|'
            r'FLOAT|REAL|DATE|TIMESTAMP|BOOLEAN|PLS_INTEGER|BINARY_INTEGER|'
            r'BINARY_FLOAT|BINARY_DOUBLE|CLOB|BLOB|NCLOB|XMLTYPE|'
            r'SYS_REFCURSOR|\w+\s*(?:%TYPE|%ROWTYPE)?)\s*(?:\([^)]*\))?)'
            r'(?:\s*:=\s*([^;]+?))?'
            r'\s*;',
            re.IGNORECASE
        )
        for m in var_pattern.finditer(text):
            name = m.group(1).upper()
            # Skip keywords
            if name in ('CURSOR', 'BEGIN', 'END', 'DECLARE', 'EXCEPTION', 'PROCEDURE', 'FUNCTION'):
                continue
            oracle_type = m.group(2).strip()
            default_val = m.group(3).strip() if m.group(3) else None
            # Skip if already captured as cursor
            if any(d['name'].upper() == name for d in decls):
                continue
            decls.append({
                'name': m.group(1),
                'oracle_type': oracle_type,
                'mssql_type': map_type(oracle_type),
                'default': default_val,
                'is_cursor': False,
                'is_exception': False,
            })

        return decls

    def _build_declare_block_text(self, decls: list[dict], param_names: set[str]) -> str:
        """Build T-SQL DECLARE block from parsed declarations.

        Uses separate DECLARE statements (safest T-SQL approach).
        """
        if not decls:
            return ""

        declare_lines = []
        for d in decls:
            name = d['name']
            if d.get('is_cursor'):
                query = d.get('cursor_query', '').strip()
                declare_lines.append(f"DECLARE {name} CURSOR FOR")
                if query:
                    declare_lines.append(f"    {query}")
            elif d.get('is_exception'):
                declare_lines.append(f"DECLARE @{name} INT = 0  -- exception flag")
            else:
                mssql_type = d['mssql_type']
                line = f"DECLARE @{name} {mssql_type}"
                if d.get('default'):
                    dv = _transform_default(d['default'])
                    line += f" = {dv}"
                declare_lines.append(line)

        return '\n'.join(declare_lines)

    def _strip_routine_header(self, body_text: str) -> str:
        """Strip the procedure/function header lines before the first BEGIN."""
        # body_text should already start with BEGIN; if not, strip header
        stripped = body_text.strip()
        if re.match(r'^BEGIN\b', stripped, re.IGNORECASE):
            return stripped
        # Find and return from BEGIN onwards
        m = re.search(r'^\s*BEGIN\b', stripped, re.IGNORECASE | re.MULTILINE)
        if m:
            return stripped[m.start():]
        return stripped

    def _add_var_prefix(self, body: str, var_names: set[str]) -> str:
        """Add @ prefix to local variable references."""
        for var in sorted(var_names, key=len, reverse=True):
            # Match the variable name as a whole word, not already prefixed with @
            pattern = r'(?<![.@\w])' + re.escape(var) + r'(?![\w.(])'
            body = re.sub(pattern, f'@{var}', body, flags=re.IGNORECASE)
        return body

    def _fix_if_structure(self, source: str) -> str:
        """Fix Oracle IF/THEN/ELSIF/END IF → T-SQL IF/BEGIN/END."""
        result = source
        # IF ... THEN → IF ... BEGIN
        result = re.sub(
            r'\bTHEN\b(?!\s*BEGIN)',
            'BEGIN',
            result, flags=re.IGNORECASE
        )
        # ELSIF → END\nELSE IF
        result = re.sub(
            r'\bELSIF\b',
            'END\nELSE IF',
            result, flags=re.IGNORECASE
        )
        # END IF → END
        result = re.sub(
            r'\bEND\s+IF\b\s*;?',
            'END',
            result, flags=re.IGNORECASE
        )
        return result

    def _fix_loop_structure(self, source: str) -> str:
        """Fix Oracle LOOP/FOR LOOP/WHILE LOOP → T-SQL WHILE/BEGIN/END."""
        result = source

        # WHILE condition LOOP → WHILE condition BEGIN
        result = re.sub(
            r'\b(WHILE\s+[^\n]+)\s+LOOP\b',
            r'\1 BEGIN',
            result, flags=re.IGNORECASE
        )

        # Simple LOOP → WHILE 1=1 BEGIN
        result = re.sub(
            r'(?<!\w)LOOP\b(?!\s+\w)',
            'WHILE 1=1 BEGIN',
            result, flags=re.IGNORECASE
        )

        # END LOOP → END
        result = re.sub(
            r'\bEND\s+LOOP\b\s*(?:;\s*)?',
            'END',
            result, flags=re.IGNORECASE
        )

        # EXIT WHEN condition → IF condition BREAK
        result = re.sub(
            r'\bEXIT\s+WHEN\s+(.+?)\s*;',
            lambda m: f"IF {m.group(1)} BREAK;",
            result, flags=re.IGNORECASE
        )

        # Plain EXIT → BREAK
        result = re.sub(r'\bEXIT\b\s*;', 'BREAK;', result, flags=re.IGNORECASE)

        return result

    def _final_cleanup(self, tsql: str, schema: str, pkg_name: str) -> str:
        """Final cleanup passes."""
        # Remove Oracle-specific end markers: END pkg_name;
        tsql = re.sub(
            r'\bEND\s+' + re.escape(pkg_name) + r'\s*;',
            'END',
            tsql, flags=re.IGNORECASE
        )

        # Fix COMMIT WORK → COMMIT TRAN
        tsql = re.sub(r'\bCOMMIT\s+WORK\b', 'COMMIT TRAN', tsql, flags=re.IGNORECASE)
        tsql = re.sub(r'\bCOMMIT\b(?!\s+TRAN)', 'COMMIT TRAN', tsql, flags=re.IGNORECASE)

        # Fix ROLLBACK WORK → ROLLBACK TRAN
        tsql = re.sub(r'\bROLLBACK\s+WORK\b', 'ROLLBACK TRAN', tsql, flags=re.IGNORECASE)
        tsql = re.sub(r'\bROLLBACK\b(?!\s+TRAN)', 'ROLLBACK TRAN', tsql, flags=re.IGNORECASE)

        # SAVEPOINT sp → SAVE TRAN sp
        tsql = re.sub(r'\bSAVEPOINT\s+(\w+)', r'SAVE TRAN \1', tsql, flags=re.IGNORECASE)

        # String concatenation || → +
        tsql = tsql.replace('||', '+')

        # Remove trailing semicolons on END statements
        tsql = re.sub(r'\bEND\s*;', 'END', tsql, flags=re.IGNORECASE)

        return tsql


# ---------------------------------------------------------------------------
# Integration with existing pipeline
# ---------------------------------------------------------------------------

def run_ast_convert(config: AppConfig) -> list[ConversionResult]:
    """Run AST-based conversion on all extracted package bodies."""
    from .utils import sanitize_name

    output_dir = Path(config.conversion.output_dir)
    manifest = load_manifest(output_dir)
    converter = AstConverter()
    results = []

    extracted_dir = output_dir / "extracted"
    converted_dir = ensure_dir(output_dir / "converted_ast")

    skip_set = set(s.upper() for s in config.conversion.skip_objects)

    for obj in manifest["objects"]:
        owner = obj["owner"]
        name = obj["name"]
        obj_type = obj["type"]

        if name.upper() in skip_set:
            continue
        if obj_type != "PACKAGE BODY":
            continue

        source_path = extracted_dir / owner / "PACKAGE_BODY" / f"{name}.sql"
        if not source_path.exists():
            logger.warning(f"[AST] Source not found: {source_path}")
            continue

        source = read_file(source_path)
        schema = config.conversion.schema_mapping.get(name, sanitize_name(name))

        logger.info(f"[AST] Converting {owner}.{name} ...")
        pkg_results = converter.convert_package_body(
            source=source,
            pkg_name=name,
            schema=schema,
            output_dir=converted_dir,
        )
        results.extend(pkg_results)

    # Save summary
    summary = {
        "engine": "ast",
        "total": len(results),
        "success": sum(1 for r in results if r.success),
        "failed": sum(1 for r in results if not r.success),
        "with_manual_review": sum(1 for r in results if r.manual_review),
    }
    write_file(
        converted_dir / "ast_conversion_summary.json",
        json.dumps(summary, indent=2, ensure_ascii=False)
    )
    logger.info(f"[AST] Done: {summary['success']}/{summary['total']} succeeded")
    return results
