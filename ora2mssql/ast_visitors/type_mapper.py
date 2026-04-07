"""Oracle → MSSQL data type mapping utilities."""
import re

# Oracle → MSSQL exact type map
TYPE_MAP = {
    "NUMBER": "DECIMAL(38,10)",
    "INTEGER": "INT",
    "INT": "INT",
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
    "VARCHAR2": "NVARCHAR(MAX)",
    "NVARCHAR2": "NVARCHAR(MAX)",
    "CHAR": "NCHAR(1)",
    "NCHAR": "NCHAR(1)",
    "CLOB": "NVARCHAR(MAX)",
    "NCLOB": "NVARCHAR(MAX)",
    "BLOB": "VARBINARY(MAX)",
    "LONG": "NVARCHAR(MAX)",
    "RAW": "VARBINARY(MAX)",
    "DATE": "DATETIME2(0)",
    "TIMESTAMP": "DATETIME2(7)",
    "TIMESTAMP WITH TIME ZONE": "DATETIMEOFFSET",
    "TIMESTAMP WITH LOCAL TIME ZONE": "DATETIME2(7)",
    "INTERVAL YEAR TO MONTH": "INT",
    "INTERVAL DAY TO SECOND": "BIGINT",
    "ROWID": "VARCHAR(18)",
    "UROWID": "VARCHAR(4000)",
    "XMLTYPE": "XML",
    "SYS_REFCURSOR": "CURSOR",
}


def map_type(oracle_type: str) -> str:
    """Map an Oracle type string to MSSQL type string."""
    s = oracle_type.strip()
    upper = s.upper()

    # NUMBER(p,s)
    m = re.match(r'NUMBER\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', upper)
    if m:
        return f"DECIMAL({m.group(1)},{m.group(2)})"

    # NUMBER(p)
    m = re.match(r'NUMBER\s*\(\s*(\d+)\s*\)', upper)
    if m:
        p = int(m.group(1))
        if p <= 4:
            return "SMALLINT"
        elif p <= 9:
            return "INT"
        elif p <= 18:
            return "BIGINT"
        else:
            return f"DECIMAL({p},0)"

    # VARCHAR2(n BYTE|CHAR) / NVARCHAR2(n)
    m = re.match(r'N?VARCHAR2\s*\(\s*(\d+)\s*(?:BYTE|CHAR)?\s*\)', upper)
    if m:
        n = int(m.group(1))
        return "NVARCHAR(MAX)" if n > 4000 else f"NVARCHAR({n})"

    # CHAR(n)
    m = re.match(r'NCHAR\s*\(\s*(\d+)\s*\)', upper)
    if m:
        return f"NCHAR({m.group(1)})"
    m = re.match(r'CHAR\s*\(\s*(\d+)\s*\)', upper)
    if m:
        return f"NCHAR({m.group(1)})"

    # TIMESTAMP(n)
    m = re.match(r'TIMESTAMP\s*\(\s*(\d+)\s*\)', upper)
    if m:
        return f"DATETIME2({m.group(1)})"

    # RAW(n)
    m = re.match(r'RAW\s*\(\s*(\d+)\s*\)', upper)
    if m:
        return f"VARBINARY({m.group(1)})"

    # Exact match
    if upper in TYPE_MAP:
        return TYPE_MAP[upper]

    # %TYPE / %ROWTYPE — keep as-is with comment
    if '%TYPE' in upper or '%ROWTYPE' in upper:
        return f"NVARCHAR(MAX) /*{s}*/"

    return s  # unknown — preserve original
