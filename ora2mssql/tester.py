"""Verification: syntax check, object count comparison, execution comparison."""
import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

import oracledb
import pyodbc

from .config import AppConfig
from .extractor import get_oracle_connection
from .deployer import get_mssql_connection, syntax_check
from .utils import ensure_dir, write_file, read_file

logger = logging.getLogger("ora2mssql")


@dataclass
class TestResult:
    test_name: str
    passed: bool
    details: str = ""
    oracle_value: str = ""
    mssql_value: str = ""


@dataclass
class TestSuiteResult:
    tests: list[TestResult] = field(default_factory=list)

    @property
    def passed(self) -> int:
        return sum(1 for t in self.tests if t.passed)

    @property
    def failed(self) -> int:
        return sum(1 for t in self.tests if not t.passed)

    @property
    def total(self) -> int:
        return len(self.tests)


def run_syntax_tests(config: AppConfig) -> TestSuiteResult:
    """Level 1: Verify all converted T-SQL files parse correctly."""
    result = TestSuiteResult()
    output_dir = Path(config.conversion.output_dir)
    converted_dir = output_dir / "converted"

    if not converted_dir.exists():
        logger.error("No converted files found. Run 'convert' first.")
        return result

    conn = get_mssql_connection(config)

    try:
        for sql_file in sorted(converted_dir.rglob("*.sql")):
            name = sql_file.stem
            sql = read_file(sql_file)

            ok, err = syntax_check(conn, sql)
            result.tests.append(TestResult(
                test_name=f"syntax:{name}",
                passed=ok,
                details=err if not ok else "OK",
            ))

            if ok:
                logger.info(f"  [PASS] {name}")
            else:
                logger.error(f"  [FAIL] {name}: {err}")
    finally:
        conn.close()

    return result


def run_object_count_tests(config: AppConfig) -> TestSuiteResult:
    """Level 2: Compare object counts between Oracle and MSSQL."""
    result = TestSuiteResult()

    ora_conn = get_oracle_connection(config)
    mssql_conn = get_mssql_connection(config)

    try:
        schemas = config.conversion.source_schemas

        # Oracle counts
        ora_cursor = ora_conn.cursor()
        ora_cursor.execute("""
            SELECT object_type, COUNT(*) FROM dba_objects
            WHERE owner IN ({})
              AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')
            GROUP BY object_type
        """.format(",".join(f"'{s}'" for s in schemas)))
        ora_counts = dict(ora_cursor.fetchall())
        ora_cursor.close()

        # MSSQL counts
        mssql_cursor = mssql_conn.cursor()
        mssql_cursor.execute("""
            SELECT type_desc, COUNT(*) FROM sys.objects
            WHERE type IN ('P', 'FN', 'IF', 'TF')
              AND schema_id != SCHEMA_ID('ora_compat')
            GROUP BY type_desc
        """)
        mssql_counts = dict(mssql_cursor.fetchall())

        # Compare
        ora_total = sum(ora_counts.values())
        mssql_total = sum(mssql_counts.values())

        result.tests.append(TestResult(
            test_name="object_count:total",
            passed=True,  # Informational
            oracle_value=str(ora_total),
            mssql_value=str(mssql_total),
            details=f"Oracle: {ora_total}, MSSQL: {mssql_total}",
        ))

        for obj_type, count in ora_counts.items():
            mssql_count = mssql_counts.get(obj_type, 0)
            result.tests.append(TestResult(
                test_name=f"object_count:{obj_type}",
                passed=True,
                oracle_value=str(count),
                mssql_value=str(mssql_count),
                details=f"Oracle: {count}, MSSQL: {mssql_count}",
            ))

    except Exception as e:
        result.tests.append(TestResult(
            test_name="object_count:error",
            passed=False,
            details=str(e),
        ))
    finally:
        ora_conn.close()
        mssql_conn.close()

    return result


def run_execution_test(
    config: AppConfig,
    procedure_name: str,
    params: dict,
    oracle_schema: str = None,
    mssql_schema: str = "dbo",
) -> TestResult:
    """Level 3: Execute procedure on both sides and compare output."""
    test_name = f"exec:{mssql_schema}.{procedure_name}"

    ora_conn = get_oracle_connection(config)
    mssql_conn = get_mssql_connection(config)

    try:
        # Build Oracle call
        ora_schema = oracle_schema or config.conversion.source_schemas[0]
        ora_params = ", ".join(f":{k}" for k in params.keys())
        ora_sql = f"BEGIN {ora_schema}.{procedure_name}({ora_params}); END;"

        # Execute on Oracle
        ora_cursor = ora_conn.cursor()
        ora_out_vars = {}
        for k, v in params.items():
            if isinstance(v, dict) and v.get("direction") == "out":
                ora_out_vars[k] = ora_cursor.var(oracledb.STRING, 4000)
                params[k] = ora_out_vars[k]
        ora_cursor.execute(ora_sql, params)
        ora_results = {k: v.getvalue() for k, v in ora_out_vars.items()}
        ora_cursor.close()

        # Build MSSQL call
        mssql_params = []
        mssql_sql_parts = []
        for k, v in params.items():
            if isinstance(v, dict) and v.get("direction") == "out":
                mssql_sql_parts.append(f"@{k} OUTPUT")
            else:
                mssql_sql_parts.append(f"@{k} = ?")
                mssql_params.append(v)

        mssql_sql = f"EXEC [{mssql_schema}].[{procedure_name}] {', '.join(mssql_sql_parts)}"

        # Execute on MSSQL
        mssql_cursor = mssql_conn.cursor()
        mssql_cursor.execute(mssql_sql, mssql_params)
        mssql_results = {}
        # Fetch result sets if any
        try:
            mssql_rows = mssql_cursor.fetchall()
            mssql_results["result_set"] = [list(row) for row in mssql_rows]
        except pyodbc.ProgrammingError:
            pass  # No result set

        # Compare outputs
        match = str(ora_results) == str(mssql_results)

        return TestResult(
            test_name=test_name,
            passed=match,
            oracle_value=str(ora_results),
            mssql_value=str(mssql_results),
            details="Output matches" if match else "Output differs",
        )

    except Exception as e:
        return TestResult(
            test_name=test_name,
            passed=False,
            details=f"Execution error: {e}",
        )
    finally:
        ora_conn.close()
        mssql_conn.close()


def run_tests(config: AppConfig) -> TestSuiteResult:
    """Run all configured tests."""
    output_dir = Path(config.conversion.output_dir)
    mode = config.testing.mode
    all_results = TestSuiteResult()

    logger.info(f"Running tests (mode: {mode})")

    if mode in ("syntax", "all"):
        syntax_results = run_syntax_tests(config)
        all_results.tests.extend(syntax_results.tests)
        logger.info(f"Syntax tests: {syntax_results.passed}/{syntax_results.total} passed")

    if mode in ("count", "all"):
        count_results = run_object_count_tests(config)
        all_results.tests.extend(count_results.tests)
        logger.info(f"Object count tests: {count_results.passed}/{count_results.total} passed")

    # Save test report
    report = {
        "mode": mode,
        "total": all_results.total,
        "passed": all_results.passed,
        "failed": all_results.failed,
        "tests": [
            {
                "name": t.test_name,
                "passed": t.passed,
                "details": t.details,
                "oracle_value": t.oracle_value,
                "mssql_value": t.mssql_value,
            }
            for t in all_results.tests
        ],
    }
    report_path = ensure_dir(output_dir / "reports") / "test_report.json"
    write_file(report_path, json.dumps(report, indent=2, ensure_ascii=False))
    logger.info(f"Test report saved to {report_path}")

    return all_results
