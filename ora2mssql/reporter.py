"""Generate conversion reports in various formats."""
import json
import logging
from pathlib import Path

from rich.console import Console
from rich.table import Table

from .config import AppConfig
from .utils import read_file

logger = logging.getLogger("ora2mssql")
console = Console()


def print_conversion_summary(config: AppConfig) -> None:
    """Print a rich summary of conversion results."""
    output_dir = Path(config.conversion.output_dir)
    summary_path = output_dir / "converted" / "conversion_summary.json"

    if not summary_path.exists():
        console.print("[red]No conversion summary found. Run 'convert' first.[/red]")
        return

    summary = json.loads(read_file(summary_path))

    # Overview table
    table = Table(title="Conversion Summary")
    table.add_column("Metric", style="cyan")
    table.add_column("Count", style="green", justify="right")

    table.add_row("Total Objects", str(summary["total"]))
    table.add_row("Successful", str(summary["success"]))
    table.add_row("With Warnings", str(summary["with_warnings"]))
    table.add_row("Need Manual Review", str(summary["manual_review_needed"]))

    console.print(table)

    # Objects needing manual review
    review_objects = [o for o in summary["objects"] if o["manual_review"] > 0]
    if review_objects:
        console.print()
        review_table = Table(title="Objects Requiring Manual Review")
        review_table.add_column("Object", style="cyan")
        review_table.add_column("Type", style="yellow")
        review_table.add_column("Items", style="red", justify="right")
        review_table.add_column("Details", style="dim")

        for obj in review_objects:
            details = "; ".join(obj["manual_review_items"][:3])
            if len(obj["manual_review_items"]) > 3:
                details += f" (+{len(obj['manual_review_items']) - 3} more)"
            review_table.add_row(
                obj["name"],
                obj["type"],
                str(obj["manual_review"]),
                details,
            )

        console.print(review_table)


def print_deploy_report(config: AppConfig) -> None:
    """Print deployment results."""
    output_dir = Path(config.conversion.output_dir)
    report_path = output_dir / "reports" / "deploy_report.json"

    if not report_path.exists():
        console.print("[red]No deploy report found. Run 'deploy' first.[/red]")
        return

    report = json.loads(read_file(report_path))

    table = Table(title=f"Deploy Report {'(dry-run)' if report['dry_run'] else ''}")
    table.add_column("Metric", style="cyan")
    table.add_column("Count", style="green", justify="right")

    table.add_row("Total", str(report["total"]))
    table.add_row("Success", str(report["success"]))
    table.add_row("Failed", str(report["failed"]))
    table.add_row("Skipped", str(report["skipped"]))

    console.print(table)

    if report["errors"]:
        console.print()
        err_table = Table(title="Deploy Errors")
        err_table.add_column("Object", style="cyan")
        err_table.add_column("Error", style="red")

        for err in report["errors"]:
            err_table.add_row(err["name"], err["error"][:100])

        console.print(err_table)


def print_test_report(config: AppConfig) -> None:
    """Print test results."""
    output_dir = Path(config.conversion.output_dir)
    report_path = output_dir / "reports" / "test_report.json"

    if not report_path.exists():
        console.print("[red]No test report found. Run 'test' first.[/red]")
        return

    report = json.loads(read_file(report_path))

    table = Table(title=f"Test Report (mode: {report['mode']})")
    table.add_column("Test", style="cyan")
    table.add_column("Result", justify="center")
    table.add_column("Details", style="dim")

    for test in report["tests"]:
        status = "[green]PASS[/green]" if test["passed"] else "[red]FAIL[/red]"
        table.add_row(test["name"], status, test["details"][:80])

    console.print(table)
    console.print(f"\nTotal: {report['total']} | "
                  f"Passed: {report['passed']} | "
                  f"Failed: {report['failed']}")
