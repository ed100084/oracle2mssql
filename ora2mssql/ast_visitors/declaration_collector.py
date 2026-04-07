"""Collect variable/cursor/exception declarations from a routine's declare section."""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional

from .type_mapper import map_type


@dataclass
class VarDecl:
    """A single variable declaration."""
    name: str
    oracle_type: str
    mssql_type: str
    default_value: Optional[str] = None
    is_cursor: bool = False
    cursor_query: Optional[str] = None
    is_exception: bool = False
    token_start: int = -1
    token_stop: int = -1


class DeclarationCollector:
    """
    Walks Seq_of_declare_specsContext (Oracle declare section) and collects
    variable/cursor/exception declarations.
    """

    def __init__(self):
        self.declarations: list[VarDecl] = []

    def collect(self, routine_ctx) -> list[VarDecl]:
        self.declarations = []
        self._visit(routine_ctx)
        return self.declarations

    # ------------------------------------------------------------------

    def _visit(self, ctx):
        from ora2mssql.parser.PlSqlParser import PlSqlParser

        if isinstance(ctx, PlSqlParser.Variable_declarationContext):
            self._handle_var(ctx)
            return
        if isinstance(ctx, PlSqlParser.Cursor_declarationContext):
            self._handle_cursor(ctx)
            return
        if isinstance(ctx, PlSqlParser.Exception_declarationContext):
            self._handle_exception(ctx)
            return
        # Don't recurse into the body (only collect from declare section)
        if isinstance(ctx, PlSqlParser.BodyContext):
            return

        if not hasattr(ctx, 'children') or ctx.children is None:
            return
        for child in ctx.children:
            self._visit(child)

    def _handle_var(self, ctx):
        """Variable_declarationContext: IdentifierContext Type_specContext [Default_value_partContext] ;"""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        name = ""
        type_text = ""
        default_val = None

        for child in (ctx.children or []):
            cname = type(child).__name__
            if not name and isinstance(child, PlSqlParser.IdentifierContext):
                name = child.getText()
            elif isinstance(child, (PlSqlParser.Type_specContext,
                                     PlSqlParser.DatatypeContext)):
                type_text = child.getText()
            elif isinstance(child, PlSqlParser.Default_value_partContext):
                # Default_value_part: ':=' expression
                # Get everything after ':='
                raw = child.getText()
                if ':=' in raw:
                    default_val = raw.split(':=', 1)[1].strip()
                else:
                    default_val = raw

        if not name:
            return
        mssql_type = map_type(type_text) if type_text else "NVARCHAR(MAX)"
        self.declarations.append(VarDecl(
            name=name,
            oracle_type=type_text,
            mssql_type=mssql_type,
            default_value=default_val,
            token_start=ctx.start.tokenIndex,
            token_stop=ctx.stop.tokenIndex,
        ))

    def _handle_cursor(self, ctx):
        """Cursor_declarationContext: CURSOR IdentifierContext IS select_statement"""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        children = ctx.children or []
        name = ""
        query_parts = []
        found_is = False

        for child in children:
            cname = type(child).__name__
            text = child.getText()
            if cname == "TerminalNodeImpl" and text.upper() == "CURSOR":
                continue
            elif isinstance(child, PlSqlParser.IdentifierContext) and not name:
                name = text
            elif cname == "TerminalNodeImpl" and text.upper() == "IS":
                found_is = True
            elif found_is and text != ";":
                query_parts.append(text)

        if not name:
            return
        self.declarations.append(VarDecl(
            name=name,
            oracle_type="CURSOR",
            mssql_type="CURSOR",
            is_cursor=True,
            cursor_query=" ".join(query_parts),
            token_start=ctx.start.tokenIndex,
            token_stop=ctx.stop.tokenIndex,
        ))

    def _handle_exception(self, ctx):
        """Exception_declarationContext: IdentifierContext EXCEPTION ;"""
        from ora2mssql.parser.PlSqlParser import PlSqlParser
        children = ctx.children or []
        name = ""
        for child in children:
            if isinstance(child, PlSqlParser.IdentifierContext) and not name:
                name = child.getText()
                break
        if not name:
            return
        self.declarations.append(VarDecl(
            name=name,
            oracle_type="EXCEPTION",
            mssql_type="INT",
            is_exception=True,
            default_value="0",
            token_start=ctx.start.tokenIndex,
            token_stop=ctx.stop.tokenIndex,
        ))
