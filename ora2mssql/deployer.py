"""Deploy converted T-SQL to MSSQL database."""
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

import pyodbc

from .config import AppConfig
from .utils import ensure_dir, read_file, write_file

logger = logging.getLogger("ora2mssql")


@dataclass
class DeployResult:
    total: int = 0
    success: int = 0
    failed: int = 0
    skipped: int = 0
    errors: list[dict] = field(default_factory=list)


def get_mssql_connection(config: AppConfig) -> pyodbc.Connection:
    """Create MSSQL database connection."""
    conn_str = config.mssql.connection_string
    return pyodbc.connect(conn_str, autocommit=True)


def deploy_ora_compat(conn: pyodbc.Connection) -> None:
    """Deploy ora_compat schema and helper UDFs (Wave -1)."""
    logger.info("Deploying [ora_compat] compatibility schema and UDFs...")

    compat_sql = _get_ora_compat_sql()
    for name, sql in compat_sql:
        try:
            conn.execute(sql)
            logger.info(f"  Deployed ora_compat.{name}")
        except Exception as e:
            logger.error(f"  Failed to deploy ora_compat.{name}: {e}")


def deploy_schemas(conn: pyodbc.Connection, schemas: list[str]) -> None:
    """Create target schemas (Wave 0)."""
    for schema in schemas:
        try:
            conn.execute(f"""
                IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = '{schema}')
                    EXEC('CREATE SCHEMA [{schema}]')
            """)
            logger.info(f"  Schema [{schema}] ready")
        except Exception as e:
            logger.error(f"  Failed to create schema [{schema}]: {e}")


def deploy_object(conn: pyodbc.Connection, sql: str, name: str) -> tuple[bool, str]:
    """Deploy a single T-SQL object.

    Executes each GO batch independently so that individual SP/function failures
    do not prevent the remaining batches from being deployed.
    If CREATE OR ALTER fails with error 2010 (return type mismatch), automatically
    DROPs the old object and retries the CREATE.
    Returns (True, "") only if ALL batches succeed; otherwise (False, first_error).
    """
    import re as _re

    batches = _split_go(sql)
    errors = []
    for batch in batches:
        batch = batch.strip()
        if batch and not batch.startswith("--"):
            try:
                conn.execute(batch)
            except Exception as e:
                err_str = str(e)
                # Error 2010: return type or signature mismatch on CREATE OR ALTER.
                # Fix: DROP the old object then retry CREATE (without OR ALTER).
                if '2010' in err_str:
                    # Extract object type and qualified name from the batch header
                    m = _re.search(
                        r'CREATE\s+OR\s+ALTER\s+(FUNCTION|PROCEDURE)\s+(\[\w+\]\.\[\w+\])',
                        batch, _re.IGNORECASE
                    )
                    if m:
                        obj_type = m.group(1).upper()
                        obj_name = m.group(2)
                        try:
                            conn.execute(f"DROP {obj_type} IF EXISTS {obj_name};")
                            # Retry with CREATE (not OR ALTER)
                            retry_batch = _re.sub(
                                r'\bCREATE\s+OR\s+ALTER\b',
                                'CREATE',
                                batch, flags=_re.IGNORECASE, count=1
                            )
                            conn.execute(retry_batch)
                            logger.info(f"  [{name}] Dropped and recreated {obj_name} (error 2010)")
                            continue  # success — go to next batch
                        except Exception as e2:
                            errors.append(str(e2))
                            logger.warning(f"  [{name}] Retry after DROP failed: {e2}")
                            continue
                errors.append(err_str)
                logger.warning(f"  [{name}] Batch failed (continuing): {e}")
    if errors:
        return False, errors[0]
    return True, ""


def syntax_check(conn: pyodbc.Connection, sql: str) -> tuple[bool, str]:
    """Check T-SQL syntax without executing (SET PARSEONLY ON)."""
    try:
        conn.execute("SET PARSEONLY ON")
        batches = _split_go(sql)
        for batch in batches:
            batch = batch.strip()
            if batch and not batch.startswith("--"):
                conn.execute(batch)
        conn.execute("SET PARSEONLY OFF")
        return True, ""
    except Exception as e:
        try:
            conn.execute("SET PARSEONLY OFF")
        except Exception:
            pass
        return False, str(e)


def check_sps_in_file(conn: pyodbc.Connection, sql_path: Path) -> list[tuple[str, bool, str]]:
    """Check syntax of each SP/Function individually in a converted SQL file.

    Returns list of (sp_name, passed, error_msg) for each SP/Function found.
    """
    import re
    sql = read_file(sql_path)
    batches = _split_go(sql)
    results = []

    name_pattern = re.compile(
        r'CREATE\s+OR\s+ALTER\s+(?:PROCEDURE|FUNCTION)\s+\[[\w]+\]\.\[(\w+)\]',
        re.IGNORECASE
    )

    for batch in batches:
        batch = batch.strip()
        if not batch or batch.startswith("--"):
            continue

        m = name_pattern.search(batch)
        sp_name = m.group(1) if m else f"(batch {len(results) + 1})"

        try:
            conn.execute("SET PARSEONLY ON")
            conn.execute(batch)
            conn.execute("SET PARSEONLY OFF")
            results.append((sp_name, True, ""))
        except Exception as e:
            try:
                conn.execute("SET PARSEONLY OFF")
            except Exception:
                pass
            results.append((sp_name, False, str(e)))

    return results


def run_deploy(config: AppConfig, dry_run: bool = False, wave: int | None = None,
               object_name: str | None = None) -> DeployResult:
    """Run deployment pipeline."""
    result = DeployResult()
    output_dir = Path(config.conversion.output_dir)

    # Load deploy order
    deploy_order_path = output_dir / "analysis" / "deploy_order.json"
    if not deploy_order_path.exists():
        logger.error("deploy_order.json not found. Run 'analyze' first.")
        return result

    with open(deploy_order_path, "r", encoding="utf-8") as f:
        deploy_data = json.load(f)

    # Connect to MSSQL
    logger.info(f"Connecting to MSSQL {config.mssql.host}/{config.mssql.database}")
    try:
        conn = get_mssql_connection(config)
    except Exception as e:
        logger.error(f"MSSQL connection failed: {e}")
        return result

    try:
        # Wave -1: ora_compat UDFs
        if not dry_run and (wave is None or wave == -1):
            deploy_ora_compat(conn)

        # Wave 0: schemas
        if wave is None or wave == 0:
            schemas = deploy_data.get("schemas_needed", [])
            if not dry_run:
                deploy_schemas(conn, schemas)

        # Wave 1+: objects
        converted_dir = output_dir / "converted"

        for item in deploy_data["deploy_order"]:
            item_wave = item["wave"]
            item_name = item["name"]
            item_schema = item["target_schema"]
            item_type = item["object_type"]

            # Filter by wave
            if wave is not None and item_wave != wave:
                continue

            # Filter by object name
            if object_name and item_name.upper() != object_name.upper():
                continue

            # Skip schema creation items (already handled)
            if item_type == "SCHEMA":
                continue

            result.total += 1

            # Find converted SQL file
            sql_path = converted_dir / item_schema / f"{item_name}.sql"
            if not sql_path.exists():
                logger.warning(f"  [{item_name}] Converted file not found: {sql_path}")
                result.skipped += 1
                continue

            sql = read_file(sql_path)

            if dry_run:
                # Syntax check only
                ok, err = syntax_check(conn, sql)
                if ok:
                    logger.info(f"  [{item_name}] Syntax OK (wave {item_wave})")
                    result.success += 1
                else:
                    logger.error(f"  [{item_name}] Syntax error: {err}")
                    result.failed += 1
                    result.errors.append({"name": item_name, "error": err})
            else:
                # Actually deploy
                logger.info(f"  Deploying [{item_schema}].[{item_name}] (wave {item_wave})")
                ok, err = deploy_object(conn, sql, item_name)
                if ok:
                    result.success += 1
                else:
                    logger.error(f"  [{item_name}] Deploy failed: {err}")
                    result.failed += 1
                    result.errors.append({"name": item_name, "error": err})

    finally:
        conn.close()

    # Save deploy report
    report_path = output_dir / "reports" / "deploy_report.json"
    write_file(report_path, json.dumps({
        "dry_run": dry_run,
        "total": result.total,
        "success": result.success,
        "failed": result.failed,
        "skipped": result.skipped,
        "errors": result.errors,
    }, indent=2, ensure_ascii=False))

    logger.info(f"Deploy {'(dry-run)' if dry_run else ''}: "
                f"{result.success}/{result.total} success, {result.failed} failed")

    return result


def _split_go(sql: str) -> list[str]:
    """Split SQL by GO batch separator."""
    import re
    return re.split(r'^\s*GO\s*$', sql, flags=re.MULTILINE | re.IGNORECASE)


def _get_ora_compat_sql() -> list[tuple[str, str]]:
    """Return ora_compat UDF creation SQL statements."""
    return [
        ("schema", """
            IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'ora_compat')
                EXEC('CREATE SCHEMA [ora_compat]')
        """),
        ("INSTR", """
            CREATE OR ALTER FUNCTION [ora_compat].[INSTR](
                @str NVARCHAR(MAX),
                @sub NVARCHAR(MAX),
                @start INT = 1,
                @occurrence INT = 1
            )
            RETURNS INT
            AS
            BEGIN
                DECLARE @pos INT = 0, @found INT = 0, @search_from INT = @start;
                IF @start < 0
                BEGIN
                    SET @str = REVERSE(@str);
                    SET @sub = REVERSE(@sub);
                    SET @search_from = ABS(@start);
                END
                WHILE @found < @occurrence
                BEGIN
                    SET @pos = CHARINDEX(@sub, @str, @search_from);
                    IF @pos = 0 RETURN 0;
                    SET @found = @found + 1;
                    IF @found < @occurrence
                        SET @search_from = @pos + 1;
                END
                RETURN @pos;
            END
        """),
        ("MONTHS_BETWEEN", """
            CREATE OR ALTER FUNCTION [ora_compat].[MONTHS_BETWEEN](
                @date1 DATETIME2,
                @date2 DATETIME2
            )
            RETURNS DECIMAL(15,6)
            AS
            BEGIN
                RETURN DATEDIFF(MONTH, @date2, @date1)
                    + (DAY(@date1) - DAY(@date2)) / 31.0;
            END
        """),
        ("TO_DATE", """
            CREATE OR ALTER FUNCTION [ora_compat].[TO_DATE](
                @str NVARCHAR(200),
                @fmt NVARCHAR(100)
            )
            RETURNS DATETIME2
            AS
            BEGIN
                -- Common Oracle formats mapped to CONVERT styles
                DECLARE @result DATETIME2;
                SET @result = TRY_PARSE(@str AS DATETIME2 USING 'zh-TW');
                IF @result IS NULL
                    SET @result = TRY_CAST(@str AS DATETIME2);
                RETURN @result;
            END
        """),
        ("TO_CHAR_DATE", """
            CREATE OR ALTER FUNCTION [ora_compat].[TO_CHAR_DATE](
                @dt DATETIME2,
                @fmt NVARCHAR(100)
            )
            RETURNS NVARCHAR(200)
            AS
            BEGIN
                -- Map common Oracle date format tokens to .NET
                DECLARE @net_fmt NVARCHAR(100) = @fmt;
                SET @net_fmt = REPLACE(@net_fmt, 'YYYY', 'yyyy');
                SET @net_fmt = REPLACE(@net_fmt, 'MM', 'MM');
                SET @net_fmt = REPLACE(@net_fmt, 'DD', 'dd');
                SET @net_fmt = REPLACE(@net_fmt, 'HH24', 'HH');
                SET @net_fmt = REPLACE(@net_fmt, 'MI', 'mm');
                SET @net_fmt = REPLACE(@net_fmt, 'SS', 'ss');
                RETURN FORMAT(@dt, @net_fmt);
            END
        """),
    ]
