"""Data type mapping rules: Oracle → MSSQL."""
import re
from ..converter import ConversionRule, ConversionContext, MANUAL_REVIEW_TAG


# Oracle → MSSQL type mapping
TYPE_MAP = {
    # Exact matches (case-insensitive)
    "NUMBER": "DECIMAL(38,10)",
    "INTEGER": "INT",
    "SMALLINT": "SMALLINT",
    "FLOAT": "FLOAT",
    "REAL": "REAL",
    "BINARY_FLOAT": "REAL",
    "BINARY_DOUBLE": "FLOAT",
    "PLS_INTEGER": "INT",
    "BINARY_INTEGER": "INT",
    "NATURAL": "INT",
    "NATURALN": "INT",
    "POSITIVE": "INT",
    "POSITIVEN": "INT",
    "SIGNTYPE": "SMALLINT",
    "BOOLEAN": "BIT",
    "VARCHAR2": "NVARCHAR",
    "NVARCHAR2": "NVARCHAR",
    "CHAR": "NCHAR",
    "NCHAR": "NCHAR",
    "CLOB": "NVARCHAR(MAX)",
    "NCLOB": "NVARCHAR(MAX)",
    "BLOB": "VARBINARY(MAX)",
    "LONG": "NVARCHAR(MAX)",
    "LONG RAW": "VARBINARY(MAX)",
    "RAW": "VARBINARY",
    "DATE": "DATETIME2(0)",
    "TIMESTAMP": "DATETIME2(7)",
    "TIMESTAMP WITH TIME ZONE": "DATETIMEOFFSET",
    "TIMESTAMP WITH LOCAL TIME ZONE": "DATETIME2(7)",
    "INTERVAL YEAR TO MONTH": "INT",  # store as months
    "INTERVAL DAY TO SECOND": "BIGINT",  # store as seconds
    "ROWID": "VARCHAR(18)",
    "UROWID": "VARCHAR(4000)",
    "XMLTYPE": "XML",
    "SYS_REFCURSOR": "CURSOR",
    "RECORD": "TABLE",  # approximate
}


class DataTypeRule(ConversionRule):
    name = "datatypes"
    order = 20

    def apply(self, source: str, ctx: ConversionContext) -> str:
        result = source

        # Handle NUMBER(p,s) with precision/scale
        result = re.sub(
            r'\bNUMBER\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)',
            lambda m: f"DECIMAL({m.group(1)},{m.group(2)})",
            result, flags=re.IGNORECASE
        )

        # Handle NUMBER(p) - integer
        result = re.sub(
            r'\bNUMBER\s*\(\s*(\d+)\s*\)',
            lambda m: self._number_to_int(int(m.group(1))),
            result, flags=re.IGNORECASE
        )

        # Handle VARCHAR2(n BYTE) or VARCHAR2(n CHAR)
        # MSSQL NVARCHAR max is 4000; anything > 4000 → NVARCHAR(MAX)
        def varchar2_to_nvarchar(m):
            n = int(m.group(1))
            return f"NVARCHAR(MAX)" if n > 4000 else f"NVARCHAR({n})"

        result = re.sub(
            r'\bN?VARCHAR2\s*\(\s*(\d+)\s*(?:BYTE|CHAR)?\s*\)',
            varchar2_to_nvarchar,
            result, flags=re.IGNORECASE
        )

        # Handle CHAR(n)
        result = re.sub(
            r'\bCHAR\s*\(\s*(\d+)\s*(?:BYTE|CHAR)?\s*\)',
            lambda m: f"NCHAR({m.group(1)})",
            result, flags=re.IGNORECASE
        )

        # Handle RAW(n)
        result = re.sub(
            r'\bRAW\s*\(\s*(\d+)\s*\)',
            lambda m: f"VARBINARY({m.group(1)})",
            result, flags=re.IGNORECASE
        )

        # Handle TIMESTAMP(p)
        result = re.sub(
            r'\bTIMESTAMP\s*\(\s*(\d+)\s*\)',
            lambda m: f"DATETIME2({m.group(1)})",
            result, flags=re.IGNORECASE
        )

        # Handle %TYPE references
        result = self._resolve_percent_type(result, ctx)

        # Handle %ROWTYPE references
        result = self._handle_rowtype(result, ctx)

        # COUNT(ROWID) -> COUNT(*) (do this before ROWID is replaced by VARCHAR(18))
        result = re.sub(r'\bCOUNT\s*\(\s*ROWID\s*\)', 'COUNT(*)', result, flags=re.IGNORECASE)

        # Simple type replacements (bare keywords)
        for ora_type, mssql_type in TYPE_MAP.items():
            if ora_type in ("NUMBER", "VARCHAR2", "NVARCHAR2", "CHAR", "RAW", "TIMESTAMP"):
                continue  # Already handled with precision patterns above
            # Only replace standalone type keywords (word boundary)
            pattern = r'\b' + re.escape(ora_type) + r'\b'
            result = re.sub(pattern, mssql_type, result, flags=re.IGNORECASE)

        # Handle bare NUMBER (no precision) - must come after parameterized patterns
        result = re.sub(
            r'\bNUMBER\b(?!\s*\()',
            'DECIMAL(38,10)',
            result, flags=re.IGNORECASE
        )

        # Handle bare VARCHAR2 (no length) - unusual but possible
        result = re.sub(
            r'\bN?VARCHAR2\b(?!\s*\()',
            'NVARCHAR(4000)',
            result, flags=re.IGNORECASE
        )

        # Cap NVARCHAR(n) where n > 4000 → NVARCHAR(MAX)
        # This catches any NVARCHAR with large sizes from any source
        def cap_nvarchar(m):
            n = int(m.group(1))
            return f"NVARCHAR(MAX)" if n > 4000 else m.group(0)

        result = re.sub(
            r'\bNVARCHAR\s*\(\s*(\d+)\s*\)',
            cap_nvarchar,
            result, flags=re.IGNORECASE
        )

        # CHR(n) → CHAR(n) (Oracle CHR function → T-SQL CHAR function)
        result = re.sub(r'\bCHR\s*\(', 'CHAR(', result, flags=re.IGNORECASE)

        # Oracle BOOLEAN literals → T-SQL BIT values (1/0)
        # Must be careful not to replace within identifiers or strings.
        result = re.sub(r'\bTRUE\b', '1', result, flags=re.IGNORECASE)
        result = re.sub(r'\bFALSE\b', '0', result, flags=re.IGNORECASE)

        return result

    def _number_to_int(self, precision: int) -> str:
        """Map NUMBER(p) to appropriate integer type."""
        if precision <= 4:
            return "SMALLINT"
        elif precision <= 9:
            return "INT"
        elif precision <= 18:
            return "BIGINT"
        else:
            return f"DECIMAL({precision},0)"

    def _resolve_percent_type(self, source: str, ctx: ConversionContext) -> str:
        """Resolve table.column%TYPE to concrete MSSQL type."""
        def replace_type(m):
            table_ref = m.group(1)  # e.g., EMPLOYEES.FIRST_NAME
            parts = table_ref.upper().split(".")
            if len(parts) == 2:
                # Try with source owner prefix
                key = f"{ctx.source_owner}.{parts[0]}.{parts[1]}"
                col_info = ctx.columns.get(key)
                if col_info:
                    ora_type = col_info["data_type"]
                    precision = col_info.get("data_precision")
                    scale = col_info.get("data_scale")
                    return self._map_column_type(ora_type, precision, scale)
            ctx.add_warning(f"Could not resolve {table_ref}%TYPE")
            return f"NVARCHAR(4000) /* {MANUAL_REVIEW_TAG} unresolved {table_ref}%TYPE */"

        return re.sub(
            r'([\w.]+)%TYPE\b',
            replace_type,
            source, flags=re.IGNORECASE
        )

    def _map_column_type(self, ora_type: str, precision, scale) -> str:
        """Map a column's Oracle type to MSSQL type."""
        upper = ora_type.upper()
        if upper == "NUMBER":
            if precision and scale and scale > 0:
                return f"DECIMAL({precision},{scale})"
            elif precision:
                return self._number_to_int(precision)
            return "DECIMAL(38,10)"
        if upper in ("VARCHAR2", "NVARCHAR2"):
            return "NVARCHAR(4000)"
        return TYPE_MAP.get(upper, f"NVARCHAR(4000) /* {MANUAL_REVIEW_TAG} unmapped: {ora_type} */")

    def _handle_rowtype(self, source: str, ctx: ConversionContext) -> str:
        """Flag %ROWTYPE for manual review (needs expansion to individual vars)."""
        def replace_rowtype(m):
            table_ref = m.group(1)
            ctx.add_manual_review(f"%ROWTYPE reference: {table_ref} - expand to individual variables")
            return f"/* {MANUAL_REVIEW_TAG} %ROWTYPE {table_ref} - expand to individual @variables */"

        return re.sub(
            r'([\w.]+)%ROWTYPE\b',
            replace_rowtype,
            source, flags=re.IGNORECASE
        )
