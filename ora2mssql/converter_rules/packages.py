"""Package → Schema + SP conversion rule.

Handles:
- Unwrap PACKAGE BODY into individual procedures/functions
- Package constants → scalar functions
- Package variable references → schema-qualified calls
- CREATE OR REPLACE → CREATE OR ALTER
"""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


class PackageRule(ConversionRule):
    name = "packages"
    order = 10

    def apply(self, source: str, ctx: ConversionContext) -> str:
        if ctx.source_type == "PACKAGE":
            return f"-- Package spec {ctx.source_name}: used for analysis only\n"

        if ctx.source_type == "PACKAGE BODY":
            return self._convert_package_body(source, ctx)

        # Standalone procedure/function
        return self._convert_standalone(source, ctx)

    def _convert_standalone(self, source: str, ctx: ConversionContext) -> str:
        source = re.sub(
            r'CREATE\s+OR\s+REPLACE\s+',
            'CREATE OR ALTER ',
            source, flags=re.IGNORECASE
        )
        return source

    def _convert_package_body(self, source: str, ctx: ConversionContext) -> str:
        schema = ctx.target_schema
        output_parts = []

        output_parts.append(f"-- Converted from Oracle package body: {ctx.source_owner}.{ctx.source_name}")
        output_parts.append(f"-- Target schema: [{schema}]")
        output_parts.append("")

        procs = self._extract_subprograms(source, ctx)

        if not procs:
            ctx.add_warning("No procedures/functions found in package body")
            return f"-- Empty package body: {ctx.source_name}\n{source}"

        # Collect all subprogram names for intra-package reference qualification
        sub_names = set()
        for proc_name, proc_type, params, body in procs:
            # Skip constant functions (__const_*)
            if not proc_name.startswith('__const_'):
                sub_names.add(proc_name)

        # Track which functions get converted to procedures (for caller fixup)
        func_to_proc = set()

        for proc_name, proc_type, params, body in procs:
            output_parts.append("GO")

            actual_type = proc_type
            if proc_type == "FUNCTION" and self._needs_procedure_conversion(body):
                # T-SQL scalar functions cannot use cursors, DML, TRY/CATCH, GOTO, COMMIT
                # Convert to procedure with OUTPUT parameter for return value
                actual_type = "PROCEDURE"
                func_to_proc.add(proc_name)
                params, body = self._convert_func_to_proc(params, body)

            if actual_type == "FUNCTION":
                body = self._move_declares_into_begin(body)
                body = self._strip_function_invalid_features(body, proc_name, ctx)

            # Schema-qualify intra-package function/procedure calls
            for sub_name in sub_names:
                body = re.sub(
                    r'(?<!\[)\b' + re.escape(sub_name) + r'\s*\(',
                    f'[{schema}].[{sub_name}](',
                    body, flags=re.IGNORECASE
                )
                params = re.sub(
                    r'(?<!\[)\b' + re.escape(sub_name) + r'\s*\(',
                    f'[{schema}].[{sub_name}](',
                    params, flags=re.IGNORECASE
                )

            # Schema-qualify cross-package function calls (functions NOT in this package)
            # Only qualify UNQUALIFIED calls (no preceding PKG_NAME. or [schema]. prefix).
            cross_pkg = getattr(ctx, 'cross_pkg_functions', {})
            for func_name, func_schema in cross_pkg.items():
                if func_name.upper() in (s.upper() for s in sub_names):
                    continue  # Intra-package — already handled above
                if func_schema == schema:
                    continue  # Same schema — already handled above
                # Negative lookbehind: skip if immediately preceded by '.' or ']'
                # (meaning it already has an explicit package or schema qualifier)
                body = re.sub(
                    r'(?<![.\]])\b' + re.escape(func_name) + r'\s*\(',
                    f'[{func_schema}].[{func_name}](',
                    body, flags=re.IGNORECASE
                )

            output_parts.append(f"CREATE OR ALTER {actual_type} [{schema}].[{proc_name}]{params}")
            output_parts.append(body)
            output_parts.append("")

        return "\n".join(output_parts)

    def _extract_subprograms(self, source: str, ctx: ConversionContext) -> list[tuple[str, str, str, str]]:
        """Extract individual PROCEDURE/FUNCTION blocks from a package body.

        Returns list of (name, type, params_with_return, body_after_IS_AS).
        """
        results = []
        lines = source.split('\n')
        i = 0

        while i < len(lines):
            line = lines[i]
            stripped = line.strip()

            # Match PROCEDURE or FUNCTION declaration
            match = re.match(
                r'\s*(PROCEDURE|FUNCTION)\s+(\w+)',
                line, re.IGNORECASE
            )

            if match:
                proc_type = match.group(1).upper()
                proc_name = match.group(2)

                # Collect everything from this line until the matching END
                subprogram_lines = [line]
                j = i + 1

                # First, find the IS/AS keyword (may span multiple lines for params)
                # Check if IS/AS is already on the declaration line itself
                found_is_as = bool(re.search(r'\b(IS|AS)\s*$', line.strip(), re.IGNORECASE))
                begin_count = 0
                found_first_begin = False
                in_block_comment = False

                while j < len(lines):
                    subprogram_lines.append(lines[j])
                    stripped_j = lines[j].strip()
                    upper_j = stripped_j.upper()

                    # Track block comments for accurate BEGIN/END counting
                    if not in_block_comment:
                        if '/*' in lines[j]:
                            rest = lines[j][lines[j].index('/*'):]
                            if '*/' not in rest[2:]:
                                in_block_comment = True
                    else:
                        if '*/' in lines[j]:
                            in_block_comment = False
                        j += 1
                        continue  # Skip lines inside block comments for nesting counts

                    if not found_is_as:
                        # Look for IS or AS keyword (standalone or at end of line)
                        if re.search(r'\b(IS|AS)\s*$', stripped_j, re.IGNORECASE):
                            found_is_as = True
                    else:
                        # Count BEGIN/END nesting
                        # Match BEGIN at start of line (allowing whitespace)
                        if re.match(r'\s*BEGIN\b', lines[j], re.IGNORECASE):
                            begin_count += 1
                            found_first_begin = True

                        # Match END but NOT END IF/END LOOP/END CASE
                        # Strip inline comments before checking to avoid false matches
                        line_nc = lines[j].split('--')[0].rstrip()
                        end_match = re.match(r'\s*END\s*(IF|LOOP|CASE)\b', line_nc, re.IGNORECASE)
                        # Block END: END followed by optional name and optional semicolon, then EOL
                        # This excludes CASE expression ends like "end)" or "end ||"
                        end_plain = re.match(r'\s*END(?:\s+\w+)?\s*;?\s*$', line_nc, re.IGNORECASE) and not end_match
                        if end_plain and found_first_begin:
                            begin_count -= 1
                            if begin_count <= 0:
                                break

                    j += 1

                full_text = '\n'.join(subprogram_lines)

                # Split into: header (PROCEDURE name(...) RETURN type) and body (after IS/AS)
                # Find the IS/AS boundary
                is_as_match = re.search(
                    r'^(.*?(?:PROCEDURE|FUNCTION)\s+\w+\s*(?:\([^)]*\))?\s*(?:RETURN\s+\S+)?)\s+(IS|AS)\s*$',
                    full_text, re.IGNORECASE | re.DOTALL
                )

                if is_as_match:
                    header = is_as_match.group(1).strip()
                    body = full_text[is_as_match.end():]
                else:
                    # Fallback: split on first standalone IS/AS
                    parts = re.split(r'\b(IS|AS)\s*\n', full_text, maxsplit=1, flags=re.IGNORECASE)
                    if len(parts) >= 3:
                        header = parts[0].strip()
                        body = parts[2]
                    else:
                        header = full_text
                        body = ""

                # Extract params from header (everything after proc name)
                param_match = re.search(
                    r'(?:PROCEDURE|FUNCTION)\s+\w+\s*(.*)',
                    header, re.IGNORECASE | re.DOTALL
                )
                params_and_return = param_match.group(1).strip() if param_match else ""

                # Convert RETURN → RETURNS for functions
                params_and_return = re.sub(
                    r'\bRETURN\s+(\S+)\s*$',
                    r'RETURNS \1',
                    params_and_return, flags=re.IGNORECASE
                )

                # Add AS before body
                if params_and_return:
                    params_section = f"{params_and_return}\nAS"
                else:
                    params_section = "\nAS"

                results.append((proc_name, proc_type, params_section, body))
                i = j + 1
            else:
                # Check for package-level constants
                const_match = re.match(
                    r'\s*(\w+)\s+CONSTANT\s+(\S+)\s*:=\s*(.+?)\s*;',
                    line, re.IGNORECASE
                )
                if const_match:
                    const_name = const_match.group(1)
                    const_type = const_match.group(2)
                    const_val = const_match.group(3)
                    results.append((
                        f"__const_{const_name}",
                        "FUNCTION",
                        f"()\nRETURNS {const_type}\nAS",
                        f"\nBEGIN\n    RETURN {const_val};\nEND"
                    ))

                i += 1

        return results

    def _needs_procedure_conversion(self, body: str) -> bool:
        """Check if a function body uses features not allowed in T-SQL scalar functions.

        DML and CURSOR cause parse-time errors in scalar functions.
        EXCEPTION/TRY-CATCH and GOTO are handled by _fix_function_declares wrapper.
        """
        if re.search(r'\b(INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM)\b', body, re.IGNORECASE):
            return True
        if re.search(r'\bCURSOR\b', body, re.IGNORECASE):
            return True
        return False

    def _convert_func_to_proc(self, params: str, body: str) -> tuple[str, str]:
        """Convert function params/body to procedure with OUTPUT return parameter.

        Changes: RETURNS TYPE → adds @RETURN_VALUE TYPE OUTPUT parameter
                 RETURN expr; → SET @RETURN_VALUE = expr; RETURN;
        """
        # Extract return type from RETURNS clause
        returns_match = re.search(r'\bRETURNS\s+(\S+)', params, re.IGNORECASE)
        return_type = returns_match.group(1) if returns_match else 'DECIMAL(38,10)'

        # Remove RETURNS clause and add OUTPUT parameter
        params = re.sub(r'\s*RETURNS\s+\S+', '', params, flags=re.IGNORECASE)

        # Add @RETURN_VALUE OUTPUT parameter
        # params looks like "(param1 TYPE, param2 TYPE)\nAS"
        # Insert before the closing )
        params = re.sub(
            r'\)\s*\n\s*AS',
            f', @RETURN_VALUE {return_type} OUTPUT)\nAS',
            params, flags=re.IGNORECASE
        )

        # Convert RETURN expr; → SET @RETURN_VALUE = expr; RETURN;
        body = re.sub(
            r'\bRETURN\s+(.+?)\s*;',
            r'SET @RETURN_VALUE = \1; RETURN;',
            body, flags=re.IGNORECASE
        )

        return params, body

    def _move_declares_into_begin(self, body: str) -> str:
        """Move DECLARE statements before BEGIN into the BEGIN block.

        T-SQL functions require DECLARE inside BEGIN...END.
        """
        lines = body.split('\n')
        declare_lines = []
        other_before_begin = []
        begin_idx = None

        for idx, line in enumerate(lines):
            stripped = line.strip().upper()
            if stripped == 'BEGIN' or stripped.startswith('BEGIN '):
                begin_idx = idx
                break
            elif stripped.startswith('DECLARE ') or (stripped.startswith('DECLARE\t')):
                declare_lines.append(lines[idx])
            elif stripped and not stripped.startswith('--'):
                other_before_begin.append(lines[idx])
            else:
                other_before_begin.append(lines[idx])

        if begin_idx is None or not declare_lines:
            return body

        # Rebuild: other lines before BEGIN, then BEGIN, then DECLARE lines, then rest
        result_lines = other_before_begin + [lines[begin_idx]] + declare_lines + lines[begin_idx + 1:]
        return '\n'.join(result_lines)

    def _strip_function_invalid_features(self, body: str, proc_name: str, ctx: ConversionContext) -> str:
        """Strip features that cause parse-time errors in T-SQL scalar functions.
        
        T-SQL scalar functions do not support:
        - BEGIN TRY / END TRY / BEGIN CATCH / END CATCH
        - GOTO
        """
        # Strip BEGIN TRY and END TRY
        body = re.sub(r'^\s*BEGIN\s+TRY\b.*$', '', body, flags=re.IGNORECASE | re.MULTILINE)
        body = re.sub(r'^\s*END\s+TRY\b.*$', '', body, flags=re.IGNORECASE | re.MULTILINE)
        
        # Replace entire CATCH block
        def replace_catch(m):
            ctx.add_manual_review(f"Function {proc_name}: Exception handler removed (not supported in T-SQL function)")
            return f"/* {MANUAL_REVIEW_TAG} Exception handler removed. Original CATCH block stripped. */"
            
        body = re.sub(
            r'^\s*BEGIN\s+CATCH\b.*?^\s*END\s+CATCH\b',
            replace_catch,
            body,
            flags=re.IGNORECASE | re.MULTILINE | re.DOTALL
        )
        
        # Comment out GOTO
        def replace_goto(m):
            ctx.add_manual_review(f"Function {proc_name}: GOTO statement commented out")
            return f"{m.group(1)}/* {MANUAL_REVIEW_TAG} Function cannot contain GOTO: {m.group(2)} */"
            
        body = re.sub(
            r'^(\s*)(GOTO\s+\w+\s*;)',
            replace_goto,
            body,
            flags=re.IGNORECASE | re.MULTILINE
        )
        
        return body
