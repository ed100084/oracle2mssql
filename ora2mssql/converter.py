"""Core conversion engine - chains rule modules to transform PL/SQL to T-SQL."""
import json
import logging
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path

from .config import AppConfig
from .extractor import load_manifest
from .utils import ensure_dir, write_file, read_file

logger = logging.getLogger("ora2mssql")

MANUAL_REVIEW_TAG = "[ORA2MSSQL:MANUAL_REVIEW]"


@dataclass
class ConversionContext:
    """Context passed through the conversion pipeline."""
    source_owner: str = ""
    source_name: str = ""
    source_type: str = ""          # PROCEDURE, FUNCTION, PACKAGE, PACKAGE BODY
    target_schema: str = "dbo"
    target_name: str = ""
    warnings: list[str] = field(default_factory=list)
    manual_review: list[str] = field(default_factory=list)
    variables: dict[str, str] = field(default_factory=dict)
    package_refs: set[str] = field(default_factory=set)
    columns: dict[str, dict] = field(default_factory=dict)  # "OWNER.TABLE.COL" -> type info
    schema_mapping: dict[str, str] = field(default_factory=dict)
    # Global registry: FUNC_NAME.upper() → target_schema for cross-package qualification
    cross_pkg_functions: dict[str, str] = field(default_factory=dict)

    def add_warning(self, msg: str):
        self.warnings.append(msg)
        logger.warning(f"  [{self.source_name}] {msg}")

    def add_manual_review(self, msg: str, line_hint: str = ""):
        entry = f"{msg}" + (f" near: {line_hint[:80]}" if line_hint else "")
        self.manual_review.append(entry)


@dataclass
class ConversionResult:
    source_name: str
    source_type: str
    target_schema: str
    target_name: str
    tsql: str
    warnings: list[str] = field(default_factory=list)
    manual_review: list[str] = field(default_factory=list)
    success: bool = True


class ConversionRule(ABC):
    """Base class for all conversion rules."""
    name: str = "base"
    order: int = 0

    @abstractmethod
    def apply(self, source: str, ctx: ConversionContext) -> str:
        """Apply this rule to the source code. Returns modified source."""
        ...


class Converter:
    """Main conversion engine that chains rules."""

    def __init__(self, rules: list[ConversionRule]):
        self.rules = sorted(rules, key=lambda r: r.order)

    def convert(self, plsql_source: str, ctx: ConversionContext) -> ConversionResult:
        """Run all rules on the given PL/SQL source."""
        current = plsql_source

        for rule in self.rules:
            try:
                current = rule.apply(current, ctx)
            except Exception as e:
                ctx.add_warning(f"Rule '{rule.name}' failed: {e}")
                logger.error(f"Rule '{rule.name}' error on {ctx.source_name}: {e}")

        # Post-processing: move DECLARE inside BEGIN for functions
        current = self._fix_function_declares(current)

        # Post-processing: fix OUTPUT parameter position
        # T-SQL requires: @param TYPE OUTPUT (not @param OUTPUT TYPE)
        # Handle types like DECIMAL(38,10) with balanced parens
        def fix_output_position(m):
            param = m.group(1)  # @name
            type_str = m.group(2).strip()  # e.g., DECIMAL(38,10)
            trailing = m.group(3)  # , or )
            return f"{param} {type_str} OUTPUT{trailing}"

        current = re.sub(
            r'(@\w+)\s+OUTPUT\s+(\w+(?:\([^)]*\))?)\s*([,)])',
            fix_output_position,
            current
        )

        return ConversionResult(
            source_name=ctx.source_name,
            source_type=ctx.source_type,
            target_schema=ctx.target_schema,
            target_name=ctx.target_name,
            tsql=current,
            warnings=ctx.warnings.copy(),
            manual_review=ctx.manual_review.copy(),
        )

    def _fix_function_declares(self, source: str) -> str:
        """Move DECLARE statements between AS and BEGIN into the BEGIN block for functions.

        T-SQL functions require all DECLARE statements inside BEGIN...END.
        Also wraps BEGIN TRY functions with an outer BEGIN...END.
        """
        lines = source.split('\n')
        result_lines = []
        i = 0

        while i < len(lines):
            line = lines[i]

            # Detect function definition
            if re.match(r'CREATE\s+OR\s+ALTER\s+FUNCTION\b', line.strip(), re.IGNORECASE):
                # Collect through AS, then move DECLARE lines after BEGIN
                func_start = len(result_lines)
                result_lines.append(line)
                i += 1

                # Find AS line
                while i < len(lines):
                    result_lines.append(lines[i])
                    if lines[i].strip().upper() == 'AS':
                        i += 1
                        break
                    i += 1

                # Collect ALL lines between AS and BEGIN (or BEGIN TRY)
                # These include DECLARE, block comments, cursor definitions, etc.
                declare_lines = []
                needs_wrapper_end = False
                in_block_comment = False
                while i < len(lines):
                    stripped = lines[i].strip().upper()

                    # Track block comments
                    if in_block_comment:
                        declare_lines.append(lines[i])
                        if '*/' in lines[i]:
                            in_block_comment = False
                        i += 1
                        continue

                    if '/*' in lines[i] and '*/' not in lines[i]:
                        in_block_comment = True
                        declare_lines.append(lines[i])
                        i += 1
                        continue

                    if stripped == 'BEGIN' or (stripped.startswith('BEGIN') and not stripped.startswith('BEGIN TRY') and not stripped.startswith('BEGIN CATCH')):
                        # Plain BEGIN - insert it, then the DECLARE lines
                        result_lines.append(lines[i])  # BEGIN
                        result_lines.extend(declare_lines)
                        i += 1
                        break
                    elif stripped.startswith('BEGIN TRY'):
                        # BEGIN TRY without outer BEGIN - need to wrap in BEGIN...END
                        indent = lines[i][:len(lines[i]) - len(lines[i].lstrip())]
                        result_lines.append(f"{indent}BEGIN")
                        result_lines.extend(declare_lines)
                        result_lines.append(lines[i])  # BEGIN TRY
                        needs_wrapper_end = True
                        i += 1
                        break
                    else:
                        # Collect everything between AS and BEGIN:
                        # DECLARE, comments, block comments, cursor SELECT lines, etc.
                        declare_lines.append(lines[i])
                        i += 1

                if needs_wrapper_end:
                    # Find the END CATCH that closes this function's TRY/CATCH
                    # and add an outer END after it
                    remaining = []
                    while i < len(lines):
                        s = lines[i].strip().upper()
                        if s == 'GO' or re.match(r'CREATE\s+OR\s+ALTER\s+', s):
                            break
                        remaining.append(lines[i])
                        i += 1

                    # Find last END CATCH and add END after it
                    insert_pos = len(remaining)
                    for j in range(len(remaining) - 1, -1, -1):
                        if remaining[j].strip().upper().startswith('END CATCH'):
                            insert_pos = j + 1
                            break

                    indent = '    '
                    remaining.insert(insert_pos, f"{indent}RETURN 0;")
                    remaining.insert(insert_pos + 1, "END")

                    result_lines.extend(remaining)
            else:
                result_lines.append(line)
                i += 1

        return '\n'.join(result_lines)


def build_column_cache(manifest: dict) -> dict[str, dict]:
    """Build lookup for %TYPE resolution: 'OWNER.TABLE.COL' -> type info."""
    cache = {}
    for col in manifest.get("columns", []):
        key = f"{col['owner']}.{col['table_name']}.{col['column_name']}"
        cache[key] = col
    return cache


def create_default_converter() -> Converter:
    """Create converter with all default rules."""
    from .converter_rules.packages import PackageRule
    from .converter_rules.datatypes import DataTypeRule
    from .converter_rules.functions import FunctionRule
    from .converter_rules.syntax import SyntaxRule
    from .converter_rules.cursors import CursorRule
    from .converter_rules.exceptions import ExceptionRule
    from .converter_rules.dml import DmlRule

    rules = [
        PackageRule(),      # order=10 - structural first
        DataTypeRule(),     # order=20
        FunctionRule(),     # order=30
        SyntaxRule(),       # order=40
        CursorRule(),       # order=50
        ExceptionRule(),    # order=60
        DmlRule(),          # order=70
    ]
    return Converter(rules)


def _build_cross_pkg_registry(manifest: dict, extracted_dir, config) -> dict[str, str]:
    """Pre-scan all PACKAGE BODY sources to build FUNC_NAME → target_schema mapping.

    This enables schema-qualification of unqualified cross-package function calls.
    """
    from .utils import sanitize_name, read_file
    registry: dict[str, str] = {}
    skip_set = set(s.upper() for s in config.conversion.skip_objects)

    for obj in manifest.get("objects", []):
        if obj["type"] != "PACKAGE BODY":
            continue
        name = obj["name"]
        owner = obj["owner"]
        if name.upper() in skip_set:
            continue

        target_schema = config.conversion.schema_mapping.get(name, sanitize_name(name))
        source_path = extracted_dir / owner / "PACKAGE_BODY" / f"{name}.sql"
        if not source_path.exists():
            continue

        try:
            source = read_file(source_path)
        except Exception:
            continue

        # Extract PROCEDURE/FUNCTION names
        for m in re.finditer(r'^\s*(PROCEDURE|FUNCTION)\s+(\w+)', source,
                             re.IGNORECASE | re.MULTILINE):
            func_name = m.group(2).upper()
            # Don't overwrite if already registered (first package wins)
            if func_name not in registry:
                registry[func_name] = target_schema

    return registry


def run_convert(config: AppConfig) -> list[ConversionResult]:
    """Run conversion on all extracted objects."""
    output_dir = Path(config.conversion.output_dir)
    manifest = load_manifest(output_dir)
    column_cache = build_column_cache(manifest)
    converter = create_default_converter()

    results = []
    extracted_dir = output_dir / "extracted"
    converted_dir = ensure_dir(output_dir / "converted")

    skip_set = set(s.upper() for s in config.conversion.skip_objects)

    # Pre-scan all packages to build cross-package function registry
    cross_pkg_registry = _build_cross_pkg_registry(manifest, extracted_dir, config)
    logger.info(f"Cross-package registry: {len(cross_pkg_registry)} functions indexed")

    for obj in manifest["objects"]:
        owner = obj["owner"]
        name = obj["name"]
        obj_type = obj["type"]

        if name.upper() in skip_set:
            logger.info(f"Skipping {owner}.{name} (in skip list)")
            continue

        # Read source
        type_dir = obj_type.replace(" ", "_")
        source_path = extracted_dir / owner / type_dir / f"{name}.sql"
        if not source_path.exists():
            logger.warning(f"Source not found: {source_path}")
            continue

        plsql_source = read_file(source_path)

        # Determine target schema
        if obj_type in ("PACKAGE", "PACKAGE BODY"):
            from .utils import sanitize_name
            target_schema = config.conversion.schema_mapping.get(
                name, sanitize_name(name)
            )
        else:
            target_schema = "dbo"

        # Create context
        ctx = ConversionContext(
            source_owner=owner,
            source_name=name,
            source_type=obj_type,
            target_schema=target_schema,
            target_name=name,
            columns=column_cache,
            schema_mapping=config.conversion.schema_mapping,
            cross_pkg_functions=cross_pkg_registry,
        )

        # Convert
        logger.info(f"Converting {owner}.{name} ({obj_type})")
        result = converter.convert(plsql_source, ctx)
        results.append(result)

        # Save converted T-SQL
        out_path = converted_dir / target_schema / f"{name}.sql"
        write_file(out_path, result.tsql)

        if result.manual_review:
            logger.warning(f"  {len(result.manual_review)} items need manual review")

    # Save conversion summary
    summary = {
        "total": len(results),
        "success": sum(1 for r in results if r.success),
        "with_warnings": sum(1 for r in results if r.warnings),
        "manual_review_needed": sum(1 for r in results if r.manual_review),
        "objects": [
            {
                "name": r.source_name,
                "type": r.source_type,
                "target_schema": r.target_schema,
                "warnings": len(r.warnings),
                "manual_review": len(r.manual_review),
                "manual_review_items": r.manual_review,
            }
            for r in results
        ],
    }
    summary_path = output_dir / "converted" / "conversion_summary.json"
    write_file(summary_path, json.dumps(summary, indent=2, ensure_ascii=False))
    logger.info(f"Conversion complete: {summary['total']} objects, "
                f"{summary['manual_review_needed']} need manual review")

    return results
