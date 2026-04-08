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

    # Strip inline -- comments before splitting (they can span parameter boundaries)
    params_text = re.sub(r'--[^\n]*', '', params_text)

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

        # Fallback: if ANTLR4 parse errors caused too few routines to be found,
        # switch to regex-based routine splitting + text-level transforms.
        expected = len(re.findall(
            r'^\s*(?:PROCEDURE|FUNCTION)\s+\w+', source,
            re.IGNORECASE | re.MULTILINE
        ))
        if expected > 0 and len(routines) < max(1, expected * 0.8):
            logger.warning(
                f"[AST] ANTLR4 found only {len(routines)}/{expected} expected routines "
                f"in {pkg_name} — switching to regex fallback splitter"
            )
            return self._convert_package_body_regex_fallback(
                source=source,
                pkg_name=pkg_name,
                schema=schema,
                output_dir=output_dir,
            )

        # Step 4: Get all tokens as list
        token_stream.fill()
        all_tokens = token_stream.tokens  # list of Token objects

        # Attach set of all intra-package routine names to each routine (for qualification)
        all_routine_names = {r.name for r in routines}
        for r in routines:
            r._all_routine_names = all_routine_names

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

    def _convert_package_body_regex_fallback(
        self,
        source: str,
        pkg_name: str,
        schema: str,
        output_dir: Path,
    ) -> list[ConversionResult]:
        """Fallback: use regex-based routine splitter when ANTLR4 parse fails.

        Splits the package body into individual routines using the regex engine's
        _extract_subprograms logic, then applies the AST text-level transforms.
        """
        from .converter_rules.packages import PackageRule

        class _MinimalCtx:
            source_owner = "HRP"
            source_name = pkg_name
            source_type = "PACKAGE BODY"
            target_schema = schema
            warnings_list: list = []

            def add_warning(self, msg: str) -> None:
                self.warnings_list.append(msg)

        rule = PackageRule()
        ctx = _MinimalCtx()
        procs = rule._extract_subprograms(source, ctx)
        logger.info(f"[AST-Regex] Found {len(procs)} routines via regex in {pkg_name}")

        results: list[ConversionResult] = []
        all_routine_names = {name for name, _, _, _ in procs}

        from .ast_visitors.syntax_transformer import SyntaxTransformer

        for proc_name, proc_type, params_and_return, body in procs:
            try:
                is_function = proc_type.upper() == "FUNCTION"

                # params_and_return is params_section from _extract_subprograms:
                # procedures: "(p_a IN VARCHAR2, ...)\nAS"
                # functions:  "(p_a IN VARCHAR2, ...) RETURNS NUMBER\nAS"
                # Strip the trailing \nAS (or just AS) that _extract_subprograms appended
                params_text = re.sub(r'\s*\bAS\s*$', '', params_and_return.strip(), flags=re.IGNORECASE)
                return_type = None
                # Extract RETURNS clause for functions
                returns_m = re.search(r'\)\s*RETURNS\s+(\S+)\s*$', params_text, re.IGNORECASE)
                if returns_m:
                    return_type = returns_m.group(1)
                    params_text = params_text[:returns_m.start() + 1]  # up to and including ')'
                # Strip outer parens
                params_text = re.sub(r'^\s*\(\s*', '', params_text)
                params_text = re.sub(r'\s*\)\s*$', '', params_text)

                # Convert Oracle params to T-SQL
                params_tsql = _transform_params(params_text)
                param_names = {p.strip().lstrip('@').split()[0] for p in params_tsql.split(',') if p.strip()}
                # Fallback: extract param names from raw Oracle params
                if not param_names:
                    param_names = set(re.findall(r'^\s*(\w+)\s+(?:IN|OUT|INOUT)', params_text,
                                                  re.IGNORECASE | re.MULTILINE))

                # Build T-SQL header
                header = _build_routine_header(
                    schema=schema,
                    name=proc_name,
                    is_function=is_function,
                    params_text=params_tsql,
                    return_type=return_type,
                )

                # Create minimal SyntaxTransformer (tokens/stream not needed for text transforms)
                transformer = SyntaxTransformer(
                    tokens=None,
                    stream=None,
                    pkg_name=pkg_name,
                    routine_name=proc_name,
                    all_vars=set(),
                    all_params=param_names,
                )

                # Apply text-level transformations to the routine body
                body_tsql = self._transform_body_text(body, transformer, param_names)

                # Combine and finalize
                tsql = f"{header}\n{body_tsql}\nGO\n"
                tsql = self._final_cleanup(tsql, schema, pkg_name, all_routine_names)

                warnings: list[str] = []
                manual_review: list[str] = []
                if "TODO" in tsql:
                    manual_review.append("Contains TODO items requiring manual review")

                result = ConversionResult(
                    source_name=f"{pkg_name}.{proc_name}",
                    source_type=proc_type.upper(),
                    target_schema=schema,
                    target_name=proc_name,
                    tsql=tsql,
                    warnings=warnings,
                    manual_review=manual_review,
                    success=True,
                )
                results.append(result)

                out_path = ensure_dir(output_dir / schema) / f"{pkg_name}__{proc_name}.sql"
                write_file(out_path, tsql)
                logger.info(f"[AST-Regex] Converted {schema}.{proc_name} → {out_path}")

            except Exception as e:
                logger.error(f"[AST-Regex] Failed to convert {proc_name}: {e}", exc_info=True)
                results.append(ConversionResult(
                    source_name=f"{pkg_name}.{proc_name}",
                    source_type=proc_type.upper(),
                    target_schema=schema,
                    target_name=proc_name,
                    tsql=f"-- CONVERSION FAILED: {e}\n",
                    warnings=[str(e)],
                    success=False,
                ))

        return results

    def _wrap_source(self, source: str, pkg_name: str) -> str:
        """Add CREATE OR REPLACE PACKAGE BODY wrapper if needed.

        Input files may contain both the package SPEC and BODY (exported together
        from Oracle).  When both are present, we extract only the BODY section so
        the ANTLR4 parser does not choke on the spec syntax.
        """
        s = source.strip()

        # If the file contains a PACKAGE BODY section (possibly after a spec),
        # extract from that point onward.
        body_start = re.search(
            r'CREATE\s+OR\s+REPLACE\s+PACKAGE\s+BODY\b',
            s, re.IGNORECASE
        )
        if body_start:
            s = s[body_start.start():]
            if not s.endswith('/'):
                s += '\n/'
            return s

        # Starts with PACKAGE BODY (no CREATE OR REPLACE prefix)
        if re.match(r'PACKAGE\s+BODY', s, re.IGNORECASE):
            s = f"CREATE OR REPLACE {s}"
            if not s.endswith('/'):
                s += '\n/'
            return s

        # Bare body (starts with PROCEDURE/FUNCTION/comments)
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

        # Final cleanup — pass all routine names for intra-package qualification
        all_routine_names = getattr(routine, '_all_routine_names', None)
        tsql = self._final_cleanup(tsql, schema, pkg_name, all_routine_names)

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

        # Separate cursors from regular vars
        cursor_names = {d['name'] for d in decls if d.get('is_cursor')}
        all_var_names = {d['name'] for d in decls if not d.get('is_cursor')} | param_names

        # 3. Apply built-in function transforms to cursor SELECT queries
        for d in decls:
            if d.get('is_cursor') and d.get('cursor_query'):
                d['cursor_query'] = transformer._convert_functions(d['cursor_query'])

        # 3b. Apply @ prefix to cursor queries (they reference local vars)
        decls = self._prefix_cursor_queries(decls, all_var_names)

        # 3c. Apply built-in function transforms to declare default values
        for d in decls:
            if d.get('default') and not d.get('is_cursor'):
                d['default'] = transformer._convert_functions(d['default'])

        # 4. Apply @ prefix to default values in DECLARE
        decls = self._prefix_declare_defaults(decls, all_var_names | param_names)

        # 5. Build DECLARE block (separate DECLARE per item)
        declare_block = self._build_declare_block_text(decls, param_names)

        # 6. body_text starts with BEGIN; strip inner content for transformation
        body_only = self._strip_routine_header(body_text)
        inner_body = self._strip_begin_end(body_only)

        # 7. Apply built-in function transforms
        transformed = transformer._convert_functions(inner_body)

        # 8. Fix boolean literals
        transformed = transformer._fix_boolean(transformed)

        # 9. Convert string concatenation
        transformed = transformed.replace('||', '+')

        # 10. Convert EXCEPTION/WHEN → TRY/CATCH FIRST
        # (must be before _fix_if_structure which converts THEN → BEGIN)
        transformed = self._convert_exception_block(transformed)

        # 11. Convert := assignments → SET @var = ...
        transformed = self._convert_assignments(transformed, all_var_names)

        # 12. Add @ prefix to variables (exclude cursor names)
        transformed = self._add_var_prefix(transformed, all_var_names)

        # 13. Fix IF/THEN/ELSIF/END IF structure
        transformed = self._fix_if_structure(transformed)

        # 14. Fix LOOP / FOR LOOP / WHILE LOOP / FOR i IN range structure
        transformed = self._fix_loop_structure(transformed)

        # 15. Qualify intra-package function calls (e.g. f_hra4010_A → [schema].[f_hra4010_A])
        # (done in _final_cleanup with schema info)

        # 16. Reassemble with DECLARE + BEGIN...END
        if declare_block.strip():
            result = f"{declare_block}\nBEGIN\n{transformed}\nEND"
        else:
            result = f"BEGIN\n{transformed}\nEND"

        return result

    def _prefix_cursor_queries(self, decls: list[dict], var_names: set[str]) -> list[dict]:
        """Apply @ prefix to variable refs inside cursor SELECT queries."""
        for d in decls:
            if d.get('is_cursor') and d.get('cursor_query'):
                d['cursor_query'] = self._add_var_prefix(d['cursor_query'], var_names)
        return decls

    def _prefix_declare_defaults(self, decls: list[dict], all_names: set[str]) -> list[dict]:
        """Apply @ prefix to parameter/variable references in DECLARE default values."""
        for d in decls:
            if d.get('default'):
                # Add @ to any bare identifier that matches a param/var name
                d['default'] = self._add_var_prefix(d['default'], all_names)
        return decls

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
        max_iterations = 200
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

            # Skip EXCEPTION tokens that are inside /* ... */ block comments
            open_comments = before_exc.count('/*') - before_exc.count('*/')
            if open_comments > 0:
                # This EXCEPTION is inside a block comment — replace with a placeholder and continue
                result = result[:exc_pos] + '__EXCEPTION_IN_COMMENT__' + result[exc_pos + len('EXCEPTION'):]
                continue

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
                # No matching BEGIN — bare EXCEPTION (outer procedure level).
                # Wrap the entire before_exc in BEGIN TRY ... END TRY.
                when_text = after_exc
                # Remove trailing END; if present
                when_text = re.sub(r'\bEND\s*;?\s*$', '', when_text, flags=re.IGNORECASE).rstrip()
                catch_body = self._parse_when_clauses(when_text)
                result = (
                    "BEGIN TRY\n"
                    + before_exc.rstrip()
                    + f"\nEND TRY\nBEGIN CATCH\n{catch_body}\nEND CATCH"
                )
                break
            else:
                # end_pos not found — break to avoid infinite loop
                result = (before_exc + "\nEND TRY\nBEGIN CATCH\n" +
                          self._parse_when_clauses(after_exc) + "\nEND CATCH")
                break

        # Restore any EXCEPTION tokens that were inside block comments
        result = result.replace('__EXCEPTION_IN_COMMENT__', 'EXCEPTION')
        return result

    def _find_matching_begin_pos(self, text: str) -> Optional[int]:
        """Find the position of the last unmatched BEGIN keyword in text.

        Handles CASE...END SQL expressions so they don't confuse BEGIN/END tracking.
        Uses a unified stack: both BEGIN and CASE push; END pops from top.
        END IF / END LOOP are ignored (they close IF/LOOP, not BEGIN/CASE blocks).
        """
        # Order matters: END IF / END LOOP / END CASE must be matched before bare END
        tokens_re = re.compile(
            r'\b(END\s+IF|END\s+LOOP|END\s+CASE|BEGIN|CASE|END)\b',
            re.IGNORECASE
        )
        # Stack entries: ('BEGIN', pos) or ('CASE', pos)
        stack: list[tuple[str, int]] = []

        for m in tokens_re.finditer(text):
            kw = ' '.join(m.group(1).upper().split())  # normalise whitespace
            if kw == 'BEGIN':
                stack.append(('BEGIN', m.start()))
            elif kw == 'CASE':
                stack.append(('CASE', m.start()))
            elif kw in ('END IF', 'END LOOP', 'END CASE'):
                # Consume the corresponding non-BEGIN opener if present
                if stack and stack[-1][0] in ('CASE',):
                    stack.pop()
                # END IF / END LOOP don't pop BEGIN entries
            elif kw == 'END':
                # Pops whatever is on top (BEGIN block or CASE expression)
                if stack:
                    stack.pop()

        # Return position of last unmatched BEGIN (ignore unmatched CASEs)
        for kind, pos in reversed(stack):
            if kind == 'BEGIN':
                return pos
        return None

    def _find_closing_end(self, text: str) -> tuple[Optional[int], int]:
        """Find the first END keyword at depth 0 in text after EXCEPTION.

        Accounts for CASE...END expressions so they don't short-circuit the search.
        """
        # Order matters: END IF / END LOOP / END CASE before bare END
        tokens_re = re.compile(
            r'\b(END\s+IF|END\s+LOOP|END\s+CASE|BEGIN|CASE|END)\b',
            re.IGNORECASE
        )
        stack: list[str] = []  # 'BEGIN' or 'CASE'

        for m in tokens_re.finditer(text):
            kw = ' '.join(m.group(1).upper().split())
            if kw == 'BEGIN':
                stack.append('BEGIN')
            elif kw == 'CASE':
                stack.append('CASE')
            elif kw in ('END IF', 'END LOOP', 'END CASE'):
                if stack and stack[-1] == 'CASE':
                    stack.pop()
            elif kw == 'END':
                if stack:
                    stack.pop()
                else:
                    # depth 0 — this is the closing END we are looking for
                    end_len = m.end() - m.start()
                    rest = text[m.end():].lstrip()
                    if rest.startswith(';'):
                        return m.start(), end_len + 1 + (len(text[m.end():]) - len(rest))
                    elif re.match(r'\w+\s*;', rest):
                        semi = rest.index(';')
                        return m.start(), m.end() - m.start() + (len(text[m.end():]) - len(rest)) + semi + 1
                    return m.start(), end_len
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
        """Split Oracle routine source into (declare_section, begin_to_end).

        If source starts with a PROCEDURE/FUNCTION header, the header IS/AS line
        is skipped so only the declare variables are in declare_section.
        If source starts directly with declarations (fallback path after header
        has already been stripped), header_end stays 0.
        """
        lines = source.split('\n')
        begin_line = None

        # Find IS/AS (end of header) — only valid if PROCEDURE/FUNCTION seen first.
        # This prevents the cursor's "CURSOR x (...) IS" from being mistaken for
        # the routine header separator.
        header_end = 0
        seen_proc_keyword = False
        for i, line in enumerate(lines):
            stripped = re.sub(r'--.*$', '', line).strip().upper()
            if re.search(r'\b(PROCEDURE|FUNCTION)\b', stripped):
                seen_proc_keyword = True
            if seen_proc_keyword:
                if re.match(r'^(IS|AS)\s*$', stripped) or re.search(r'\b(IS|AS)\s*$', stripped):
                    header_end = i + 1
                    break
            if i > 50:  # give up looking for IS/AS
                break

        # Now find BEGIN in the declare section (or from the top if no header)
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
            r'CURSOR\s+(\w+)\s*(?:\([^)]*\))?\s+IS\s+((?:WITH\b|SELECT\b)[^;]+);',
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
            r'(?:CONSTANT\s+)?'  # optional CONSTANT keyword
            r'((?:N?VARCHAR2|NCHAR|CHAR|NUMBER|DECIMAL|INTEGER|INT|SMALLINT|BIGINT|'
            r'FLOAT|REAL|DATE|TIMESTAMP|BOOLEAN|PLS_INTEGER|BINARY_INTEGER|'
            r'BINARY_FLOAT|BINARY_DOUBLE|CLOB|BLOB|NCLOB|XMLTYPE|'
            r'SYS_REFCURSOR|\w+(?:\.\w+)?\s*(?:%TYPE|%ROWTYPE)?)\s*(?:\([^)]*\))?)'
            r'(?:\s*:=\s*([^;]+?))?'
            r'\s*;',
            re.IGNORECASE
        )
        # Strip cursor bodies from text before var matching (prevents FROM/WHERE etc. being parsed as vars)
        text_no_cursors = cursor_pattern.sub('', text)

        SQL_KEYWORDS = {
            'CURSOR', 'BEGIN', 'END', 'DECLARE', 'EXCEPTION', 'PROCEDURE', 'FUNCTION',
            'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'NOT', 'IN', 'BETWEEN', 'LIKE',
            'GROUP', 'ORDER', 'BY', 'HAVING', 'UNION', 'INTERSECT', 'MINUS',
            'INSERT', 'UPDATE', 'DELETE', 'INTO', 'VALUES', 'SET',
            'CREATE', 'ALTER', 'DROP', 'TABLE', 'VIEW', 'INDEX',
            'IF', 'THEN', 'ELSE', 'ELSIF', 'LOOP', 'FOR', 'WHILE', 'RETURN',
            'OPEN', 'FETCH', 'CLOSE', 'COMMIT', 'ROLLBACK', 'NULL',
            'IS', 'AS', 'OF', 'ON', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'FULL',
            'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
        }

        for m in var_pattern.finditer(text_no_cursors):
            name = m.group(1).upper()
            # Skip SQL keywords
            if name in SQL_KEYWORDS:
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

        # Variables and exceptions first, cursors last.
        # Cursors may reference local variables in their SELECT, so variables must be declared first.
        var_lines = []
        cursor_lines = []
        for d in decls:
            name = d['name']
            if d.get('is_cursor'):
                query = d.get('cursor_query', '').strip()
                cursor_lines.append(f"DECLARE {name} CURSOR FOR")
                if query:
                    cursor_lines.append(f"    {query};")
            elif d.get('is_exception'):
                var_lines.append(f"DECLARE @{name} INT = 0;  -- exception flag")
            else:
                mssql_type = d['mssql_type']
                line = f"DECLARE @{name} {mssql_type}"
                if d.get('default'):
                    dv = _transform_default(d['default'])
                    line += f" = {dv}"
                var_lines.append(line + ";")

        return '\n'.join(var_lines + cursor_lines)

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

    def _case_depth_update(self, depth: int, line: str) -> int:
        """Update CASE expression depth counter based on tokens on a line.

        CASE → +1, bare END (not END IF/LOOP/TRY/CATCH/CASE) → -1 (min 0).
        Used to avoid converting THEN/ELSE inside multi-line CASE expressions.
        """
        for m in re.finditer(
            r'\b(END\s+IF|END\s+LOOP|END\s+TRY|END\s+CATCH|END\s+CASE|CASE|END)\b',
            line, re.IGNORECASE
        ):
            kw = ' '.join(m.group(1).upper().split())
            if kw == 'CASE':
                depth += 1
            elif kw == 'END':
                depth = max(0, depth - 1)
            elif kw == 'END CASE':
                depth = max(0, depth - 1)
            # END IF, END LOOP, END TRY, END CATCH: don't change CASE depth
        return depth

    def _fix_if_structure(self, source: str) -> str:
        """Fix Oracle IF/THEN/ELSIF/END IF → T-SQL IF/BEGIN/END.

        Processes line-by-line so that commented-out Oracle code (--) is not transformed.
        Tracks CASE expression depth to avoid converting THEN/ELSE inside CASE WHEN...THEN.
        """
        lines_in = source.split('\n')
        lines_out = []
        case_depth = 0  # tracks depth inside SQL CASE expressions (cross-line)
        skip_end_if = False  # True after inline-ELSE handler; next END IF is already accounted for

        for line in lines_in:
            stripped = line.lstrip()
            is_comment = stripped.startswith('--')

            if is_comment:
                lines_out.append(line)
                continue

            # ELSIF → END\nELSE IF  (non-comment lines only)
            if re.search(r'\bELSIF\b', line, re.IGNORECASE):
                line = re.sub(r'\bELSIF\b', 'END\nELSE IF', line, flags=re.IGNORECASE)
                # After substitution line may contain \n; apply END IF + THEN→BEGIN
                # to each resulting sub-line individually, then emit and skip rest.
                sub_lines = line.split('\n')
                processed_subs = []
                for sl in sub_lines:
                    sl = re.sub(r'\bEND\s+IF\b[ \t]*;?', 'END', sl, flags=re.IGNORECASE)
                    if case_depth == 0 and re.search(r'\bTHEN\b', sl, re.IGNORECASE):
                        sl = re.sub(
                            r'^((?:(?!\bWHEN\b).)*)\bTHEN\b',
                            r'\1BEGIN',
                            sl, flags=re.IGNORECASE
                        )
                    case_depth = self._case_depth_update(case_depth, sl)
                    processed_subs.append(sl)
                lines_out.extend(processed_subs)
                continue

            # END IF → END  (skip if after inline-ELSE, which already generated END)
            if skip_end_if and re.search(r'\bEND\s+IF\b', line, re.IGNORECASE):
                line = re.sub(r'\bEND\s+IF\b[ \t]*;?', '', line, flags=re.IGNORECASE).strip()
                skip_end_if = False
                if not line:
                    continue  # drop the now-empty line
            else:
                line = re.sub(r'\bEND\s+IF\b[ \t]*;?', 'END', line, flags=re.IGNORECASE)
                if skip_end_if:
                    skip_end_if = False

            # IF ... THEN (anywhere on line, no WHEN in prefix, not inside CASE) → IF ... BEGIN
            # Handles both end-of-line THEN and single-line "IF cond THEN stmt END IF"
            if case_depth == 0 and re.search(r'\bTHEN\b', line, re.IGNORECASE):
                line = re.sub(
                    r'^((?:(?!\bWHEN\b).)*)\bTHEN\b',
                    r'\1BEGIN',
                    line, flags=re.IGNORECASE
                )

            # ELSE (not ELSE IF, not inside CASE expression) at end of line → END\nELSE\nBEGIN
            if case_depth == 0:
                m_else = re.match(r'^(\s*)ELSE\b(?!\s*IF\b)([ \t]*(?:--[^\n]*)?)$', line, re.IGNORECASE)
                if m_else:
                    indent = m_else.group(1)
                    comment = m_else.group(2)
                    # Update case_depth before emitting (ELSE line has no CASE/END tokens)
                    lines_out.append(f"{indent}END")
                    lines_out.append(f"{indent}ELSE")
                    lines_out.append(f"{indent}BEGIN{comment}")
                    continue

                # Inline ELSE: Oracle "ELSE stmt;" on one line (not ELSE IF, not comment-only)
                # e.g. "else i_end_date := p_end_date;" → "END\nELSE\nBEGIN\n  stmt\nEND"
                # After this, the following END IF is already accounted for (skip_end_if=True).
                m_inline_else = re.match(r'^(\s*)ELSE\b(?!\s*IF\b)\s+(\S.+)$', line, re.IGNORECASE)
                if m_inline_else:
                    indent = m_inline_else.group(1)
                    stmt = m_inline_else.group(2)
                    case_depth = self._case_depth_update(case_depth, stmt)
                    lines_out.append(f"{indent}END")
                    lines_out.append(f"{indent}ELSE")
                    lines_out.append(f"{indent}BEGIN")
                    lines_out.append(f"{indent}    {stmt}")
                    lines_out.append(f"{indent}END")
                    skip_end_if = True  # next END IF is already handled by the END above
                    continue

            # Update case_depth after THEN/ELSE decisions for this line
            case_depth = self._case_depth_update(case_depth, line)
            lines_out.append(line)

        result = '\n'.join(lines_out)

        # Fix Oracle BOOLEAN variable used directly as IF condition → T-SQL error 4145.
        # IF (@var) BEGIN or IF @var BEGIN (no comparison operator) → IF @var <> 0 BEGIN
        result = re.sub(
            r'\bIF\s+\((@\w+)\)\s+BEGIN\b',
            r'IF \1 <> 0 BEGIN',
            result, flags=re.IGNORECASE
        )
        result = re.sub(
            r'\bIF\s+(?!\()(@\w+)\s+BEGIN\b',
            r'IF \1 <> 0 BEGIN',
            result, flags=re.IGNORECASE
        )
        return result

    def _fix_loop_structure(self, source: str) -> str:
        """Fix Oracle LOOP/FOR LOOP/WHILE LOOP → T-SQL WHILE/BEGIN/END.

        Temporarily replaces comment lines with placeholders so that LOOP/EXIT
        patterns inside comments are not transformed.
        """
        # Protect comment lines: replace with indexed placeholders
        _COMMENT_HOLDER = '\x00COMMENT_{}\x00'
        saved_comments: list[str] = []
        lines = source.split('\n')
        protected = []
        for line in lines:
            if line.lstrip().startswith('--'):
                idx = len(saved_comments)
                saved_comments.append(line)
                protected.append(_COMMENT_HOLDER.format(idx))
            else:
                protected.append(line)
        result = '\n'.join(protected)

        # FOR i IN lower..upper LOOP → DECLARE @i INT; SET @i = lower; WHILE @i <= upper BEGIN
        def for_numeric_loop(m):
            var = m.group(1)
            lower = m.group(2).strip()
            upper = m.group(3).strip()
            return (f"DECLARE @{var} INT = {lower};\n"
                    f"WHILE @{var} <= {upper} BEGIN")
        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+(\d+)\s*\.\.\s*(\d+)\s+LOOP\b',
            for_numeric_loop,
            result, flags=re.IGNORECASE
        )

        # FOR i IN expr1..expr2 LOOP (general expression)
        def for_expr_loop(m):
            var = m.group(1)
            lower = m.group(2).strip()
            upper = m.group(3).strip()
            return (f"DECLARE @{var} INT = {lower};\n"
                    f"WHILE @{var} <= {upper} BEGIN")
        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+(.+?)\s*\.\.\s*(.+?)\s+LOOP\b',
            for_expr_loop,
            result, flags=re.IGNORECASE
        )

        # FOR REVERSE loops
        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+REVERSE\s+(.+?)\s*\.\.\s*(.+?)\s+LOOP\b',
            lambda m: (f"DECLARE @{m.group(1)} INT = {m.group(3).strip()};\n"
                       f"WHILE @{m.group(1)} >= {m.group(2).strip()} BEGIN"),
            result, flags=re.IGNORECASE
        )

        # FOR cursor loop → WHILE (fetch) BEGIN ... END  (mark for manual review)
        result = re.sub(
            r'\bFOR\s+(\w+)\s+IN\s+(\w+)\s+LOOP\b',
            lambda m: f"/* TODO: FOR cursor loop {m.group(1)} IN {m.group(2)} */\nWHILE 1=1 BEGIN  -- fetch {m.group(2)}",
            result, flags=re.IGNORECASE
        )

        # WHILE condition LOOP → WHILE condition BEGIN
        result = re.sub(
            r'\b(WHILE\s+[^\n]+)\s+LOOP\b',
            r'\1 BEGIN',
            result, flags=re.IGNORECASE
        )

        # END LOOP → END  (must come BEFORE bare LOOP substitution)
        # Use \n to preserve line separation; only eat the semicolon, not newlines
        result = re.sub(
            r'\bEND\s+LOOP\b[ \t]*;?',
            'END',
            result, flags=re.IGNORECASE
        )

        # Simple bare LOOP → WHILE 1=1 BEGIN
        # (all FOR/WHILE ... LOOP patterns already handled above)
        result = re.sub(
            r'\bLOOP\b',
            'WHILE 1=1 BEGIN',
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

        # Restore protected comment lines
        for idx, comment_line in enumerate(saved_comments):
            result = result.replace(_COMMENT_HOLDER.format(idx), comment_line)

        return result

    def _final_cleanup(self, tsql: str, schema: str, pkg_name: str,
                       routine_names: Optional[set[str]] = None) -> str:
        """Final cleanup passes."""
        # Remove Oracle-specific end markers: END pkg_name;
        tsql = re.sub(
            r'\bEND\s+' + re.escape(pkg_name) + r'\s*;',
            'END',
            tsql, flags=re.IGNORECASE
        )

        # Remove empty parameter list () from no-parameter procedure declarations.
        # T-SQL: "CREATE OR ALTER PROCEDURE [s].[p]" (no parens); Oracle emits empty ().
        tsql = re.sub(
            r'(?m)(CREATE\s+OR\s+ALTER\s+PROCEDURE\s+\[\w+\]\.\[\w+\])\s*\n\s*\(\s*\)',
            r'\1',
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

        # Qualify intra-package function/procedure calls
        # e.g. f_hra4010_A(...) → [EHRPHRA3_PKG].[f_hra4010_A](...)
        if routine_names:
            for rname in sorted(routine_names, key=len, reverse=True):
                # Only qualify bare calls (not already qualified)
                pattern = r'(?<!\[)(?<!\.)(?<!\w)' + re.escape(rname) + r'(?!\w)(?=\s*\()'
                replacement = f"[{schema}].[{rname}]"
                tsql = re.sub(pattern, replacement, tsql, flags=re.IGNORECASE)

        # pkg_name.routine → [schema].[routine]
        tsql = re.sub(
            re.escape(pkg_name) + r'\.' + r'(\w+)',
            lambda m: f"[{schema}].[{m.group(1)}]",
            tsql, flags=re.IGNORECASE
        )

        # Cross-package calls: OTHER_PKG_NAME.routine → [other_schema].[routine]
        # Handles EHRPHRAFUNC_PKG.func(...) called from EHRPHRA12_PKG, etc.
        # Uses the OTHER package's schema name (lowercase pkg name), not the current schema.
        _KNOWN_PKGS = ['EHRPHRA3_PKG', 'EHRPHRA12_PKG', 'EHRPHRAFUNC_PKG']
        for _other_pkg in _KNOWN_PKGS:
            if _other_pkg.lower() != pkg_name.lower():
                _other_schema = _other_pkg.lower()
                tsql = re.sub(
                    re.escape(_other_pkg) + r'\.(\w+)',
                    lambda m, s=_other_schema: f"[{s}].[{m.group(1)}]",
                    tsql, flags=re.IGNORECASE
                )

        # hrpuser.PACKAGE.proc(args) → EXEC proc args  (three-part Oracle call → T-SQL EXEC)
        # Matches the full arg list (one level of nested parens) to produce EXEC without outer parens.
        tsql = re.sub(
            r'\bhrpuser\.(\w+)\.(\w+)\s*\(((?:[^)(]|\([^)]*\))*)\)',
            lambda m: f"/* TODO: hrpuser.{m.group(1)}.{m.group(2)}(...) */ EXEC {m.group(2)} {m.group(3)}",
            tsql, flags=re.IGNORECASE
        )
        # hrpuser.proc(args) two-part form
        tsql = re.sub(
            r'\bhrpuser\.(\w+)\s*\(((?:[^)(]|\([^)]*\))*)\)',
            lambda m: f"/* TODO: hrpuser.{m.group(1)}(...) */ EXEC {m.group(1)} {m.group(2)}",
            tsql, flags=re.IGNORECASE
        )

        # Convert standalone [schema].[proc](args); without EXEC to EXEC [schema].[proc] args;
        # Handles both single-line and multi-line calls (with one level of nested parens in args).
        # Only matches when the proc call is at the START of a statement (beginning of line).
        # This avoids false positives for function calls in SELECT/SET context.
        tsql = re.sub(
            r'(?m)^(\s*)(\[\w+\]\.\[\w+\])\s*\(((?:[^)(]|\([^)]*\))*)\)\s*;',
            r'\1EXEC \2 \3;',
            tsql, flags=re.IGNORECASE | re.DOTALL
        )

        # Fix T-SQL function DECLARE inside functions (functions need DECLARE inside BEGIN)
        tsql = self._fix_function_declare_placement(tsql)

        # Convert Oracle cursor attributes
        tsql = self._convert_cursor_syntax(tsql)

        # Convert SELECT...INTO @var FROM → SELECT @var = ... FROM
        tsql = self._convert_select_into(tsql)

        # Strip Oracle named parameter syntax: param => value → value
        tsql = self._strip_named_params(tsql)

        # Add missing aliases to unaliased derived tables in FROM clauses
        # T-SQL requires aliases; Oracle does not. Pattern: FROM (subquery) ; or FROM (subquery)\n
        tsql = self._add_derived_table_aliases(tsql)

        # Convert Oracle NULL statement (standalone NULL; → T-SQL null/empty statement)
        # Use semicolon rather than a comment so that T-SQL's parser sees a real statement.
        # A comment-only BEGIN/END block followed by ELSE causes "near ELSE" parse errors.
        tsql = re.sub(r'(?m)^(\s*)NULL\s*;\s*$', r'\1;  -- null statement', tsql, flags=re.IGNORECASE)

        # Eliminate null-body IF branches: "IF cond BEGIN ; END ELSE BEGIN content END"
        # → "IF NOT (cond) BEGIN content END"
        # When the IF branch is only a null statement, negate the condition and use the ELSE content.
        tsql = re.sub(
            r'(?m)^(\s*)IF\b([^\n]+?)BEGIN\s*\n\s*;\s*--\s*null statement[^\n]*\n\s*END\s*\n\s*ELSE\s*\n\s*BEGIN\b',
            lambda m: f'{m.group(1)}IF NOT ({m.group(2).strip()}) BEGIN',
            tsql, flags=re.IGNORECASE
        )

        # Strip Oracle outer-join indicator (+) — T-SQL uses explicit LEFT JOIN syntax.
        # Removing (+) converts the join to an implicit inner join (semantics may differ).
        tsql = re.sub(r'\s*\(\+\)', '', tsql)

        # Remove incorrectly @ -prefixed numeric literals (e.g. @10 → 10).
        # Variable names in Oracle/T-SQL must start with a letter or _, never a digit.
        tsql = re.sub(r'@(\d+)\b', r'\1', tsql)

        # Quote T-SQL reserved word MERGE when used as a column name.
        # Column MERGE: preceded by whitespace/operator, NOT followed by INTO/USING (DML).
        tsql = re.sub(
            r'(?<=[=(,\s])\bMERGE\b(?!\s+(?:INTO|USING)\b)',
            '[MERGE]', tsql, flags=re.IGNORECASE
        )

        # Parameterized cursor OPEN: OPEN cursor_name(args) → OPEN cursor_name
        # T-SQL cursors don't support parameterized OPEN calls.
        tsql = re.sub(r'\bOPEN\s+(\w+)\s*\([^)]*\)\s*;', r'OPEN \1;', tsql, flags=re.IGNORECASE)

        # Convert SQLCODE / SQLERRM
        tsql = re.sub(r'\bSQLCODE\b', 'ERROR_NUMBER()', tsql, flags=re.IGNORECASE)
        tsql = re.sub(r'\bSQLERRM\b', 'ERROR_MESSAGE()', tsql, flags=re.IGNORECASE)

        # Fix string concatenation with ERROR_NUMBER() / ERROR_MESSAGE() — T-SQL requires CAST.
        # Pattern: 'string' + ERROR_NUMBER() or ERROR_NUMBER() + 'string'
        # Only wrap in CAST when adjacent to + (string concat context).
        tsql = re.sub(
            r"(\+\s*)ERROR_NUMBER\(\)",
            r"\1CAST(ERROR_NUMBER() AS NVARCHAR)",
            tsql, flags=re.IGNORECASE
        )
        tsql = re.sub(
            r"ERROR_NUMBER\(\)(\s*\+)",
            r"CAST(ERROR_NUMBER() AS NVARCHAR)\1",
            tsql, flags=re.IGNORECASE
        )
        tsql = re.sub(
            r"(\+\s*)ERROR_MESSAGE\(\)",
            r"\1CAST(ERROR_MESSAGE() AS NVARCHAR)",
            tsql, flags=re.IGNORECASE
        )
        tsql = re.sub(
            r"ERROR_MESSAGE\(\)(\s*\+)",
            r"CAST(ERROR_MESSAGE() AS NVARCHAR)\1",
            tsql, flags=re.IGNORECASE
        )

        # Oracle CHR(n) → T-SQL CHAR(n)
        tsql = re.sub(r'\bCHR\s*\(', 'CHAR(', tsql, flags=re.IGNORECASE)

        # Oracle MOD(x, y) → T-SQL (x % y)
        # Simple two-arg form; handles non-nested args.
        def _convert_mod(m):
            return f'({m.group(1).strip()} % {m.group(2).strip()})'
        tsql = re.sub(
            r'\bMOD\s*\(([^,()]+),\s*([^()]+)\)',
            _convert_mod,
            tsql, flags=re.IGNORECASE
        )

        # Oracle ROUND(x) single-arg → T-SQL ROUND(x, 0) (T-SQL requires scale arg).
        # Avoid matching ROUND(x, y) which already has two args.
        tsql = re.sub(
            r'\bROUND\s*\(([^,()]+)\)',
            r'ROUND(\1, 0)',
            tsql, flags=re.IGNORECASE
        )

        # Oracle TO_NUMBER(val, 'mask') was converted to CAST(val, mask AS type).
        # Remove the format mask — T-SQL CAST doesn't support it.
        # Pattern: CAST(expr, digits AS type) → CAST(expr AS type)
        tsql = re.sub(
            r'\bCAST\s*\(([^,\n]+),\s*\d+\s+AS\s+(\w+(?:\(\d+(?:,\s*\d+)?\))?)\)',
            r'CAST(\1 AS \2)',
            tsql, flags=re.IGNORECASE
        )

        # Comment out Oracle UTL_SMTP procedure calls (no T-SQL equivalent).
        # Replace entire statement line(s) with a TODO comment.
        tsql = re.sub(
            r'(?m)^([ \t]*)(\w+\.(?:open_connection|helo|mail|rcpt|open_data|write_raw_data|close_data|quit)\s*\([^;]*\))\s*;',
            r'\1-- TODO(utl_smtp): \2;',
            tsql, flags=re.IGNORECASE
        )
        # Also handle SET var = utl_smtp.*
        tsql = re.sub(
            r'(?m)^([ \t]*)(SET\s+@\w+\s*=\s*\w+\.(?:open_connection|connection)\s*\([^;]*\))\s*;',
            r'\1-- TODO(utl_smtp): \2;',
            tsql, flags=re.IGNORECASE
        )
        # Handle DECLARE @var utl_smtp.connection → DECLARE @var NVARCHAR(MAX)
        tsql = re.sub(
            r'\butl_smtp\.connection\b',
            'NVARCHAR(MAX)',
            tsql, flags=re.IGNORECASE
        )

        # Fix EXEC calls where an arg contains a string concatenation expression
        # (T-SQL EXEC positional args don't allow expressions — must use a variable).
        # Pattern: EXEC [schema].[proc] ...,\n     'string'+CAST(ERROR_NUMBER() AS NVARCHAR);
        # Fix: extract expression to DECLARE @__exec_arg; SET @__exec_arg = expr; then EXEC uses @__exec_arg
        tsql = re.sub(
            r'(?m)^([ \t]*)(EXEC\s+\S+(?:[ \t]+[^\n]+,)?)\s*\n'
            r'([ \t]*)([^\n;]*\+CAST\(ERROR_(?:NUMBER|MESSAGE)\(\)[^\n;]*);',
            lambda m: (
                f"{m.group(1)}DECLARE @__exec_arg NVARCHAR(MAX);\n"
                f"{m.group(1)}SET @__exec_arg = {m.group(4).strip()};\n"
                f"{m.group(1)}{m.group(2)}\n"
                f"{m.group(3)}@__exec_arg;"
            ),
            tsql, flags=re.IGNORECASE
        )

        # Convert Oracle block labels <<label>> → label: (T-SQL GOTO label)
        tsql = re.sub(r'<<(\w+)>>', r'\1:', tsql)

        # Convert RAISE_APPLICATION_ERROR
        tsql = re.sub(
            r'\bRAISE_APPLICATION_ERROR\s*\(\s*(-?\d+)\s*,\s*(.+?)\)',
            lambda m: f"RAISERROR({m.group(2)}, 16, 1)",
            tsql, flags=re.IGNORECASE
        )

        # Convert Oracle ROWNUM references
        # Remove rownum from window function ORDER BY clauses (not valid in T-SQL)
        tsql = re.sub(
            r'(ORDER\s+BY\s+\w+(?:\s+(?:ASC|DESC))?)\s*,\s*ROWNUM\b',
            r'\1',
            tsql, flags=re.IGNORECASE
        )
        # WHERE ROWNUM = 1 → 1=1 /* TODO: use TOP 1 */
        tsql = re.sub(
            r'\bROWNUM\s*=\s*1\b',
            '1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */',
            tsql, flags=re.IGNORECASE
        )
        # AND/WHERE ROWNUM <= N → comment (regex engine approach)
        tsql = re.sub(
            r'\bAND\s+ROWNUM\s*<=\s*(\d+)',
            r'/* TODO: ROWNUM<=\1 converted */',
            tsql, flags=re.IGNORECASE
        )
        tsql = re.sub(
            r'\bWHERE\s+ROWNUM\s*<=\s*(\d+)',
            r'/* TODO: ROWNUM<=\1 converted */',
            tsql, flags=re.IGNORECASE
        )

        # Deduplicate inline DECLARE statements in procedure body.
        # Multiple cursor FOR loops may each emit "DECLARE @__dummy INT" (or similar),
        # causing T-SQL error 134 (variable already declared in the same batch).
        tsql = self._deduplicate_inline_declares(tsql)

        # Deduplicate T-SQL labels: if a label name appears more than once,
        # suffix each occurrence (and its matching GOTO) with _1, _2, ...
        tsql = self._deduplicate_labels(tsql)

        return tsql

    def _deduplicate_labels(self, tsql: str) -> str:
        """Rename duplicate T-SQL label definitions and their GOTOs.

        T-SQL error 132: label name already declared in the same batch.
        Oracle allows the same label name in different loop scopes; T-SQL does not.

        Strategy:
          1. Scan for all label definitions (word followed by colon on its own line).
          2. For labels that appear more than once, number them sequentially.
          3. For each occurrence, find the GOTO targeting that label between
             the previous occurrence (or start) and the current label position,
             and suffix the GOTO with the same number.
        """
        # Find all label definitions: lines like "   LabelName:"
        label_def_re = re.compile(r'^([ \t]*)(\w+):([ \t]*)$', re.MULTILINE)

        # Count occurrences of each label name
        from collections import Counter
        label_counts: Counter = Counter()
        for m in label_def_re.finditer(tsql):
            label_counts[m.group(2).upper()] += 1

        # Only process labels that appear more than once
        dup_labels = {name for name, cnt in label_counts.items() if cnt > 1}
        if not dup_labels:
            return tsql

        for label_name in sorted(dup_labels):
            # Find all definition positions (case-insensitive)
            pattern = re.compile(
                r'^([ \t]*)(' + re.escape(label_name) + r'):([ \t]*)$',
                re.MULTILINE | re.IGNORECASE
            )
            positions = [(m.start(), m.end(), m) for m in pattern.finditer(tsql)]
            if len(positions) <= 1:
                continue

            # Process in reverse order so positions don't shift
            # For each label occurrence (by position, ascending), assign number 1..N
            # and update the most recent preceding GOTO for this label
            goto_re = re.compile(
                r'\bGOTO\s+(' + re.escape(label_name) + r')\b',
                re.IGNORECASE
            )

            # Build list of all label and GOTO positions with their type
            events = []
            for start, end, m in positions:
                events.append(('label', start, end, m))
            for m in goto_re.finditer(tsql):
                events.append(('goto', m.start(), m.end(), m))
            events.sort(key=lambda e: e[1])

            # Assign suffix numbers: each label gets the next number,
            # GOTOs get the same number as the NEXT label after them
            label_num = 0
            # First pass: assign numbers to labels
            label_nums = {}  # position → number
            for kind, start, end, m in events:
                if kind == 'label':
                    label_num += 1
                    label_nums[start] = label_num

            # Second pass: match GOTOs to next label
            goto_nums = {}  # position → number
            label_positions = sorted(label_nums.keys())
            for kind, start, end, m in events:
                if kind == 'goto':
                    # Find the next label after this GOTO
                    next_label = next((p for p in label_positions if p > start), None)
                    if next_label is not None:
                        goto_nums[start] = label_nums[next_label]
                    else:
                        # No next label — use the last label
                        goto_nums[start] = label_num

            # Apply replacements in reverse order to preserve positions
            all_replacements = []
            for kind, start, end, m in events:
                if kind == 'label':
                    n = label_nums[start]
                    suffix = f"_{n}"
                    # Replace the label name in the match
                    all_replacements.append((
                        m.start(2), m.end(2),
                        m.group(2) + suffix
                    ))
                elif kind == 'goto' and start in goto_nums:
                    n = goto_nums[start]
                    suffix = f"_{n}"
                    # Replace the label reference in GOTO
                    all_replacements.append((
                        m.start(1), m.end(1),
                        m.group(1) + suffix
                    ))

            all_replacements.sort(key=lambda r: r[0], reverse=True)
            tsql_list = list(tsql)
            for rep_start, rep_end, rep_text in all_replacements:
                tsql_list[rep_start:rep_end] = list(rep_text)
            tsql = ''.join(tsql_list)

        return tsql

    def _deduplicate_inline_declares(self, tsql: str) -> str:
        """Remove duplicate inline DECLARE statements in a routine body.

        Multiple cursor FOR loops may emit identical DECLARE lines (e.g. DECLARE @__dummy INT),
        causing T-SQL error 134 (variable name already declared in the same batch).
        Keeps the first occurrence; subsequent identical DECLARE lines are commented out.
        """
        declare_re = re.compile(r'^\s*DECLARE\s+(@\w+)\b', re.IGNORECASE)
        seen: set[str] = set()
        out_lines = []
        for line in tsql.split('\n'):
            m = declare_re.match(line)
            if m:
                vname = m.group(1).lower()
                if vname in seen:
                    out_lines.append('-- ' + line.lstrip() + '  -- deduplicated')
                    continue
                seen.add(vname)
            out_lines.append(line)
        return '\n'.join(out_lines)

    def _convert_cursor_syntax(self, tsql: str) -> str:
        """Convert Oracle cursor syntax to T-SQL."""
        # %NOTFOUND → @@FETCH_STATUS <> 0
        tsql = re.sub(r'(\w+)\s*%\s*NOTFOUND', '@@FETCH_STATUS <> 0', tsql, flags=re.IGNORECASE)
        # %FOUND → @@FETCH_STATUS = 0
        tsql = re.sub(r'(\w+)\s*%\s*FOUND', '@@FETCH_STATUS = 0', tsql, flags=re.IGNORECASE)
        # %ROWCOUNT → @@ROWCOUNT
        tsql = re.sub(r'(\w+)\s*%\s*ROWCOUNT', '@@ROWCOUNT', tsql, flags=re.IGNORECASE)
        # %ISOPEN → 1=1 (always true; T-SQL cursor open state not easily trackable)
        tsql = re.sub(r'(\w+)\s*%\s*ISOPEN', '1=1 /*%ISOPEN*/', tsql, flags=re.IGNORECASE)

        # FETCH cursor_name INTO var1, var2 → FETCH NEXT FROM cursor_name INTO @var1, @var2
        def fix_fetch(m):
            cursor_name = m.group(1)
            vars_part = m.group(2)
            return f"FETCH NEXT FROM {cursor_name} INTO {vars_part}"
        tsql = re.sub(
            r'\bFETCH\s+(\w+)\s+INTO\s+(.+?)(?=;|\n)',
            fix_fetch,
            tsql, flags=re.IGNORECASE
        )

        # OPEN cursor_name — already correct in T-SQL
        # CLOSE cursor_name — already correct in T-SQL
        # Add DEALLOCATE after CLOSE if missing
        def add_deallocate(m):
            cursor_name = m.group(1)
            return f"CLOSE {cursor_name};\n    DEALLOCATE {cursor_name}"
        tsql = re.sub(
            r'\bCLOSE\s+(\w+)\s*;',
            add_deallocate,
            tsql, flags=re.IGNORECASE
        )

        return tsql

    def _convert_select_into(self, tsql: str) -> str:
        """Convert Oracle SELECT expr INTO @var FROM → T-SQL SELECT @var = expr FROM."""
        # Pattern: SELECT expr1, expr2 INTO @var1, @var2 FROM ...
        # This is complex for multiple columns. Handle single-column first.
        def fix_select_into(m):
            select_list = m.group(1).strip()
            into_vars = m.group(2).strip()
            from_clause = m.group(3)

            # Split select list and into variables
            sel_cols = [c.strip() for c in _split_params(select_list)]
            into_v = [v.strip() for v in _split_params(into_vars)]

            if len(sel_cols) != len(into_v):
                # Can't match, leave with comment
                return f"SELECT {select_list} /*INTO {into_vars}*/ FROM {from_clause}"

            # Build T-SQL: SELECT @v1 = col1, @v2 = col2 FROM ...
            assignments = ', '.join(
                f"{v} = {c}" if v.startswith('@') else f"@{v} = {c}"
                for v, c in zip(into_v, sel_cols)
            )
            return f"SELECT {assignments}\n    FROM {from_clause}"

        # Two-pass approach: find SELECT...INTO...FROM blocks line by line
        # to avoid catastrophic backtracking on large SQL.
        lines = tsql.split('\n')
        out_lines = []
        i = 0
        while i < len(lines):
            line = lines[i]
            # Look for SELECT ... INTO on this line or spanning next lines
            if re.match(r'\s*SELECT\b', line, re.IGNORECASE):
                # Accumulate lines until we find INTO and FROM or hit ;
                block_lines = [line]
                j = i + 1
                found_into = 'INTO' in line.upper()
                found_from = 'FROM' in line.upper() and found_into
                while j < len(lines) and not found_from:
                    bl = lines[j]
                    block_lines.append(bl)
                    bl_up = bl.upper().strip()
                    if not found_into and 'INTO' in bl_up:
                        found_into = True
                    if found_into and 'FROM' in bl_up:
                        found_from = True
                        break
                    if ';' in bl:
                        break
                    j += 1

                block = '\n'.join(block_lines)
                # Strip comment lines and inline comments before regex matching so that
                # commented-out columns/variables don't confuse the column count.
                block_no_comments = '\n'.join(
                    '' if l.strip().startswith('--') else re.sub(r'\s*--[^\n]*', '', l)
                    for l in block_lines
                )
                # Try single-line pattern on the accumulated block
                m = re.match(
                    r'(\s*SELECT\s+)([\s\S]+?)\s+INTO\s+((?:@?\w+\s*(?:,\s*@?\w+\s*)*)?)\s+FROM\b([\s\S]*)',
                    block_no_comments, re.IGNORECASE
                )
                if m and found_into and found_from:
                    select_list = m.group(2).strip()
                    into_vars = m.group(3).strip()
                    from_rest = 'FROM' + m.group(4)
                    sel_cols = [c.strip() for c in _split_params(select_list)]
                    into_v = [v.strip() for v in _split_params(into_vars)]
                    # Strip column aliases: "expr AS alias" (with/without space) or bare "expr alias"
                    def strip_alias(col):
                        col = col.strip()
                        # Remove trailing "AS alias" (handles no-space case like "))AS alias")
                        col = re.sub(r'\s*\bAS\s+\w+\s*$', '', col, flags=re.IGNORECASE).strip()
                        # Remove bare alias after closing paren: "func(...) alias"
                        col = re.sub(r'(\))\s+\w+\s*$', r'\1', col).strip()
                        return col
                    sel_cols = [strip_alias(c) for c in sel_cols]
                    if len(sel_cols) == len(into_v) and into_v:
                        assignments = ', '.join(
                            f"{v} = {c}" if v.startswith('@') else f"@{v} = {c}"
                            for v, c in zip(into_v, sel_cols)
                        )
                        out_lines.append(m.group(1) + assignments)
                        out_lines.append('    ' + from_rest)
                    else:
                        out_lines.append(f"SELECT {select_list} /*INTO {into_vars}*/ FROM{m.group(4)}")
                    i = j + 1
                    continue
                else:
                    out_lines.append(line)
            else:
                out_lines.append(line)
            i += 1
        tsql = '\n'.join(out_lines)
        return tsql

    def _strip_named_params(self, tsql: str) -> str:
        """Strip Oracle named parameter syntax: func(param => value) → func(value).

        In T-SQL, named parameters are not supported.
        """
        # Match: identifier => expression (in function call context)
        # Remove the identifier => part
        tsql = re.sub(
            r'@?\w+\s*=>\s*',
            '',
            tsql
        )
        return tsql

    def _add_derived_table_aliases(self, tsql: str) -> str:
        """Add missing aliases to unaliased derived tables.

        T-SQL requires FROM (subquery) AS alias; Oracle does not.
        Finds FROM ( ... ) with no following alias and inserts AS _dt_N.
        Recursively processes nested subqueries so all levels get aliases.
        """
        # SQL keywords that may follow a derived table closing paren instead of an alias
        _KW = {
            'WHERE', 'ON', 'GROUP', 'ORDER', 'HAVING', 'UNION', 'INTERSECT', 'EXCEPT',
            'MINUS', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'CROSS', 'FULL',
            'AND', 'OR', 'NOT', 'BEGIN', 'END', 'GO', 'ROLLBACK', 'COMMIT', 'SET',
            'RETURN', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'IF', 'ELSE',
            'WHILE', 'FOR', 'FETCH', 'CLOSE', 'OPEN', 'DEALLOCATE',
        }
        from_pat = re.compile(r'\bFROM\s*\(', re.IGNORECASE)

        # Use a mutable counter shared across all recursive calls
        counter_ref = [0]

        def _process(text: str) -> str:
            result = []
            i = 0
            while i < len(text):
                m = from_pat.search(text, i)
                if not m:
                    result.append(text[i:])
                    break

                result.append(text[i:m.end()])  # up to and including '('
                start = m.end()

                # Walk to find matching closing paren
                depth = 1
                j = start
                in_str = False
                str_char = ''
                while j < len(text) and depth > 0:
                    ch = text[j]
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

                # Recursively process the inner content (excluding closing ')')
                inner_content = text[start:j - 1]  # content between '(' and ')'
                processed_inner = _process(inner_content)
                result.append(processed_inner)
                result.append(')')  # re-add the closing paren

                # Check what follows the closing ')'
                rest = text[j:]
                m2 = re.match(r'^(\s*)(AS\s+)?(\w+|\[[\w\s]+\])?', rest, re.IGNORECASE)
                following_word = (m2.group(3) or '').upper() if m2 else ''

                if not following_word or following_word in _KW or following_word in ('', ';'):
                    # No alias — insert one
                    counter_ref[0] += 1
                    result.append(f' AS _dt{counter_ref[0]}')

                i = j

            return ''.join(result)

        return _process(tsql)

    def _fix_function_declare_placement(self, tsql: str) -> str:
        """T-SQL scalar functions require DECLARE inside BEGIN..END (not between AS and BEGIN)."""
        # Only applies to FUNCTION, not PROCEDURE
        if not re.match(r'CREATE\s+OR\s+ALTER\s+FUNCTION', tsql.strip(), re.IGNORECASE):
            return tsql

        # Find the AS line
        lines = tsql.split('\n')
        as_idx = None
        begin_idx = None
        for i, line in enumerate(lines):
            stripped = line.strip().upper()
            if stripped == 'AS':
                as_idx = i
            elif as_idx is not None and re.match(r'^BEGIN\b', stripped):
                begin_idx = i
                break

        if as_idx is None or begin_idx is None:
            return tsql

        # Collect DECLARE lines between AS and BEGIN.
        # Lines that are part of a CURSOR FOR declaration (spanning multiple lines)
        # must also go into declare_section.
        declare_section = []
        other_between = []
        in_cursor_body = False  # True while inside a multi-line cursor SELECT
        for i in range(as_idx + 1, begin_idx):
            line = lines[i]
            stripped = line.strip().upper()
            if stripped.startswith('DECLARE') or stripped == '' or in_cursor_body:
                declare_section.append(line)
                if re.search(r'CURSOR\s+FOR\s*$', stripped):
                    in_cursor_body = True   # next lines are cursor SELECT
                if in_cursor_body and ';' in line:
                    in_cursor_body = False  # cursor SELECT ended
            else:
                other_between.append(line)
                in_cursor_body = False

        if not declare_section:
            return tsql

        # Reconstruct: header up to AS, BEGIN, DECLARE lines, body
        result_lines = lines[:as_idx + 1]  # up to and including AS
        result_lines.extend(other_between)  # non-DECLARE lines between AS and BEGIN
        result_lines.append(lines[begin_idx])  # BEGIN
        result_lines.extend(declare_section)   # DECLARE moved inside BEGIN
        result_lines.extend(lines[begin_idx + 1:])  # rest of body
        return '\n'.join(result_lines)


# ---------------------------------------------------------------------------
# Integration with existing pipeline
# ---------------------------------------------------------------------------

def run_ast_convert(config: AppConfig, package_filter: str | None = None) -> list[ConversionResult]:
    """Run AST-based conversion on all extracted package bodies."""
    from .utils import sanitize_name

    output_dir = Path(config.conversion.output_dir)
    manifest = load_manifest(output_dir)
    converter = AstConverter()
    results = []

    extracted_dir = output_dir / "extracted"
    converted_dir = ensure_dir(output_dir / "converted_ast")

    skip_set = set(s.upper() for s in config.conversion.skip_objects)
    pkg_filter = package_filter.upper() if package_filter else None

    for obj in manifest["objects"]:
        owner = obj["owner"]
        name = obj["name"]
        obj_type = obj["type"]

        if name.upper() in skip_set:
            continue
        if pkg_filter and name.upper() != pkg_filter:
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
