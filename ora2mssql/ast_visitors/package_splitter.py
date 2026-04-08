"""Split a Package Body parse tree into individual procedure/function routines."""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class RoutineInfo:
    """Metadata about a single procedure or function inside a package body."""
    name: str
    is_function: bool
    start_token_index: int
    stop_token_index: int
    params: list[tuple[str, str, str]] = field(default_factory=list)
    return_type: Optional[str] = None


class PackageSplitter:
    """
    Walks the parse tree and extracts each Procedure_bodyContext /
    Function_bodyContext as a RoutineInfo.
    """

    def __init__(self, tokens):
        self.tokens = tokens
        self.routines: list[RoutineInfo] = []

    def split(self, tree_ctx) -> list[RoutineInfo]:
        self.routines = []
        self._visit(tree_ctx)
        return self.routines

    # ------------------------------------------------------------------

    def _visit(self, ctx):
        from ora2mssql.parser.PlSqlParser import PlSqlParser

        if isinstance(ctx, PlSqlParser.Procedure_bodyContext):
            self._handle_procedure(ctx)
            return  # don't recurse deeper
        if isinstance(ctx, PlSqlParser.Function_bodyContext):
            self._handle_function(ctx)
            return

        if not hasattr(ctx, 'children') or ctx.children is None:
            return
        for child in ctx.children:
            self._visit(child)

    def _handle_procedure(self, ctx):
        name = self._get_identifier_name(ctx)
        params = self._get_params(ctx)
        self.routines.append(RoutineInfo(
            name=name,
            is_function=False,
            start_token_index=ctx.start.tokenIndex,
            stop_token_index=ctx.stop.tokenIndex,
            params=params,
        ))

    def _handle_function(self, ctx):
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        name = self._get_identifier_name(ctx)
        params = self._get_params(ctx)
        return_type = self._get_return_type(ctx)
        self.routines.append(RoutineInfo(
            name=name,
            is_function=True,
            start_token_index=ctx.start.tokenIndex,
            stop_token_index=ctx.stop.tokenIndex,
            params=params,
            return_type=return_type,
        ))

    def _get_identifier_name(self, ctx) -> str:
        """Get the first IdentifierContext child text."""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        for child in (ctx.children or []):
            if isinstance(child, PlSqlParser.IdentifierContext):
                return child.getText()
        return "unknown"

    def _get_params(self, ctx) -> list[tuple[str, str, str]]:
        """Extract (name, direction, oracle_type) from ParameterContext children."""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        params = []
        for child in (ctx.children or []):
            if isinstance(child, PlSqlParser.ParameterContext):
                params.append(self._parse_parameter(child))
        return params

    def _parse_parameter(self, ctx) -> tuple[str, str, str]:
        """Parse a ParameterContext into (name, direction, type_text)."""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        name = ""
        direction = "IN"
        type_text = ""
        default_val = ""

        for child in (ctx.children or []):
            cname = type(child).__name__
            token_text = child.getText().upper()

            if isinstance(child, PlSqlParser.Parameter_nameContext):
                name = child.getText()
            elif cname == "TerminalNodeImpl" and token_text in ("IN", "OUT", "INOUT"):
                direction = token_text
            elif cname == "TerminalNodeImpl" and direction == "IN" and token_text == "OUT":
                direction = "IN OUT"
            elif isinstance(child, (PlSqlParser.Type_specContext,
                                     PlSqlParser.DatatypeContext)):
                type_text = child.getText()
            elif isinstance(child, PlSqlParser.Default_value_partContext):
                default_val = child.getText()

        return (name, direction, type_text)

    def _get_return_type(self, ctx) -> str:
        """Get RETURN type from a Function_bodyContext."""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        found_return = False
        for child in (ctx.children or []):
            cname = type(child).__name__
            if cname == "TerminalNodeImpl" and child.getText().upper() == "RETURN":
                found_return = True
            elif found_return:
                if isinstance(child, (PlSqlParser.Type_specContext,
                                       PlSqlParser.DatatypeContext)):
                    return child.getText()
                t = child.getText().upper()
                if t not in ("IS", "AS", "BEGIN"):
                    return child.getText()
        return "NVARCHAR(MAX)"
