"""Extract PL/SQL source code from Oracle database."""
import json
import logging
from dataclasses import dataclass, field, asdict
from pathlib import Path

import oracledb

from .config import AppConfig
from .utils import ensure_dir, write_file

logger = logging.getLogger("ora2mssql")

# Oracle object types to extract
OBJECT_TYPES = ("PROCEDURE", "FUNCTION", "PACKAGE", "PACKAGE BODY")


@dataclass
class OracleObject:
    owner: str
    name: str
    object_type: str
    source: str = ""
    line_count: int = 0


@dataclass
class ColumnInfo:
    owner: str
    table_name: str
    column_name: str
    data_type: str
    data_length: int = 0
    data_precision: int | None = None
    data_scale: int | None = None


@dataclass
class Dependency:
    owner: str
    name: str
    object_type: str
    referenced_owner: str
    referenced_name: str
    referenced_type: str


@dataclass
class ExtractionResult:
    objects: list[OracleObject] = field(default_factory=list)
    dependencies: list[Dependency] = field(default_factory=list)
    columns: list[ColumnInfo] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


def _init_thick_mode():
    """Initialize oracledb thick mode with Oracle Client."""
    try:
        oracledb.init_oracle_client(
            lib_dir=r"C:\app\client\ed100084\product\19.0.0\client_1\bin"
        )
    except oracledb.ProgrammingError:
        pass  # Already initialized


def get_oracle_connection(config: AppConfig) -> oracledb.Connection:
    """Create Oracle database connection using thick mode (for 11gR2 support)."""
    _init_thick_mode()
    ora = config.oracle
    kwargs = {
        "user": ora.user,
        "password": ora.password,
        "dsn": ora.dsn,
    }
    if ora.mode and ora.mode.upper() == "SYSDBA":
        kwargs["mode"] = oracledb.AUTH_MODE_SYSDBA
    return oracledb.connect(**kwargs)


def extract_source(conn: oracledb.Connection, schemas: list[str],
                    include_objects: list[str] | None = None) -> list[OracleObject]:
    """Extract source code for PL/SQL objects."""
    objects: dict[str, OracleObject] = {}

    where_parts = [
        "owner IN ({})".format(",".join(f"'{s}'" for s in schemas)),
        "type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')",
    ]
    if include_objects:
        where_parts.append(
            "name IN ({})".format(",".join(f"'{o}'" for o in include_objects))
        )

    sql = """
        SELECT owner, name, type, line, text
        FROM dba_source
        WHERE {}
        ORDER BY owner, name, type, line
    """.format(" AND ".join(where_parts))

    cursor = conn.cursor()
    cursor.execute(sql)

    for row in cursor:
        owner, name, obj_type, line, text = row
        key = f"{owner}.{name}.{obj_type}"
        if key not in objects:
            objects[key] = OracleObject(owner=owner, name=name, object_type=obj_type)
        objects[key].source += (text or "")
        objects[key].line_count = line

    cursor.close()
    logger.info(f"Extracted {len(objects)} PL/SQL objects")
    return list(objects.values())


def extract_dependencies(conn: oracledb.Connection, schemas: list[str],
                          include_objects: list[str] | None = None) -> list[Dependency]:
    """Extract dependency relationships between objects."""
    where_parts = [
        "owner IN ({})".format(",".join(f"'{s}'" for s in schemas)),
        "referenced_owner IN ({})".format(",".join(f"'{s}'" for s in schemas)),
        "type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')",
        "referenced_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')",
    ]
    if include_objects:
        where_parts.append(
            "name IN ({})".format(",".join(f"'{o}'" for o in include_objects))
        )
    sql = """
        SELECT owner, name, type, referenced_owner, referenced_name, referenced_type
        FROM dba_dependencies
        WHERE {}
    """.format(" AND ".join(where_parts))

    cursor = conn.cursor()
    cursor.execute(sql)

    deps = []
    for row in cursor:
        deps.append(Dependency(
            owner=row[0], name=row[1], object_type=row[2],
            referenced_owner=row[3], referenced_name=row[4], referenced_type=row[5],
        ))

    cursor.close()
    logger.info(f"Extracted {len(deps)} dependencies")
    return deps


def extract_columns(conn: oracledb.Connection, schemas: list[str]) -> list[ColumnInfo]:
    """Extract column type info for %TYPE resolution."""
    sql = """
        SELECT owner, table_name, column_name, data_type,
               data_length, data_precision, data_scale
        FROM dba_tab_columns
        WHERE owner IN ({})
        ORDER BY owner, table_name, column_name
    """.format(",".join(f"'{s}'" for s in schemas))

    cursor = conn.cursor()
    cursor.execute(sql)

    columns = []
    for row in cursor:
        columns.append(ColumnInfo(
            owner=row[0], table_name=row[1], column_name=row[2],
            data_type=row[3], data_length=row[4] or 0,
            data_precision=row[5], data_scale=row[6],
        ))

    cursor.close()
    logger.info(f"Extracted {len(columns)} column definitions")
    return columns


def run_extract(config: AppConfig) -> ExtractionResult:
    """Run full extraction pipeline."""
    result = ExtractionResult()
    schemas = config.conversion.source_schemas
    output_dir = Path(config.conversion.output_dir)

    logger.info(f"Connecting to Oracle {config.oracle.host}:{config.oracle.port}/{config.oracle.sid}")

    try:
        conn = get_oracle_connection(config)
    except Exception as e:
        result.errors.append(f"Oracle connection failed: {e}")
        logger.error(f"Oracle connection failed: {e}")
        return result

    try:
        # Extract all data
        include = config.conversion.include_objects or None
        result.objects = extract_source(conn, schemas, include_objects=include)
        result.dependencies = extract_dependencies(conn, schemas, include_objects=include)
        result.columns = extract_columns(conn, schemas)

        # Save extracted source files
        extracted_dir = ensure_dir(output_dir / "extracted")
        for obj in result.objects:
            # Organize by owner/type/name.sql
            obj_type_dir = obj.object_type.replace(" ", "_")
            file_path = extracted_dir / obj.owner / obj_type_dir / f"{obj.name}.sql"
            write_file(file_path, obj.source)

        # Save manifest (metadata + column cache)
        manifest = {
            "objects": [
                {
                    "owner": o.owner,
                    "name": o.name,
                    "type": o.object_type,
                    "line_count": o.line_count,
                }
                for o in result.objects
            ],
            "dependencies": [asdict(d) for d in result.dependencies],
            "columns": [asdict(c) for c in result.columns],
        }
        manifest_path = output_dir / "extracted" / "manifest.json"
        write_file(manifest_path, json.dumps(manifest, indent=2, ensure_ascii=False))
        logger.info(f"Manifest saved to {manifest_path}")

    except Exception as e:
        result.errors.append(f"Extraction error: {e}")
        logger.error(f"Extraction error: {e}")
    finally:
        conn.close()

    return result


def load_manifest(output_dir: Path) -> dict:
    """Load previously extracted manifest."""
    manifest_path = output_dir / "extracted" / "manifest.json"
    if not manifest_path.exists():
        raise FileNotFoundError(f"Manifest not found: {manifest_path}. Run 'extract' first.")
    with open(manifest_path, "r", encoding="utf-8") as f:
        return json.load(f)
