"""CLI entry point for ora2mssql tool."""
import click
from rich.console import Console

from .config import load_config
from .utils import setup_logging

console = Console()


@click.group()
@click.option("--config", "-c", default="config.yaml", help="Config file path")
@click.option("--verbose", "-v", is_flag=True, help="Verbose output")
@click.pass_context
def main(ctx, config, verbose):
    """Oracle PL/SQL to MSSQL T-SQL conversion tool."""
    ctx.ensure_object(dict)
    ctx.obj["config_path"] = config
    ctx.obj["verbose"] = verbose
    setup_logging(verbose)


@main.command()
@click.pass_context
def extract(ctx):
    """Extract PL/SQL source code from Oracle."""
    config = load_config(ctx.obj["config_path"])
    from .extractor import run_extract

    console.print("[bold]Extracting PL/SQL source from Oracle...[/bold]")
    result = run_extract(config)

    if result.errors:
        console.print(f"[red]Errors: {len(result.errors)}[/red]")
        for e in result.errors:
            console.print(f"  [red]{e}[/red]")
    else:
        console.print(f"[green]Extracted {len(result.objects)} objects, "
                       f"{len(result.dependencies)} dependencies, "
                       f"{len(result.columns)} column definitions[/green]")


@main.command()
@click.pass_context
def analyze(ctx):
    """Analyze dependencies and compute deployment order."""
    config = load_config(ctx.obj["config_path"])
    from .analyzer import run_analyze

    console.print("[bold]Analyzing dependencies...[/bold]")
    result = run_analyze(config)

    if result.errors:
        console.print(f"[red]Errors: {len(result.errors)}[/red]")
    else:
        console.print(f"[green]Deploy order: {len(result.deploy_order)} items, "
                       f"{len(result.schemas_needed)} schemas, "
                       f"{len(result.cycles)} cycles found[/green]")


@main.command()
@click.option("--engine", type=click.Choice(["regex", "ast"]), default=None,
              help="Conversion engine: 'regex' (default) or 'ast' (ANTLR4)")
@click.option("--package", "package_name", default=None,
              help="Convert specific package only (e.g. EHRPHRA3_PKG)")
@click.pass_context
def convert(ctx, engine, package_name):
    """Convert PL/SQL to T-SQL."""
    config = load_config(ctx.obj["config_path"])
    if engine:
        config.conversion.engine = engine

    console.print(f"[bold]Converting PL/SQL to T-SQL (engine={config.conversion.engine})...[/bold]")

    if config.conversion.engine == "ast":
        from .ast_converter import run_ast_convert
        results = run_ast_convert(config, package_filter=package_name)
        console.print(f"[green]AST conversion: {sum(1 for r in results if r.success)}/{len(results)} routines[/green]")
    else:
        from .converter import run_convert
        from .reporter import print_conversion_summary
        results = run_convert(config)
        print_conversion_summary(config)


@main.command()
@click.option("--dry-run", is_flag=True, help="Syntax check only, don't deploy")
@click.option("--wave", type=int, default=None, help="Deploy specific wave only")
@click.option("--object", "object_name", default=None, help="Deploy specific object")
@click.pass_context
def deploy(ctx, dry_run, wave, object_name):
    """Deploy converted T-SQL to MSSQL."""
    config = load_config(ctx.obj["config_path"])
    from .deployer import run_deploy
    from .reporter import print_deploy_report

    mode = "dry-run" if dry_run else "live"
    console.print(f"[bold]Deploying to MSSQL ({mode})...[/bold]")
    result = run_deploy(config, dry_run=dry_run, wave=wave, object_name=object_name)

    print_deploy_report(config)


@main.command()
@click.option("--mode", type=click.Choice(["syntax", "count", "all"]), default=None,
              help="Test mode (overrides config)")
@click.pass_context
def test(ctx, mode):
    """Run verification tests."""
    config = load_config(ctx.obj["config_path"])
    if mode:
        config.testing.mode = mode

    from .tester import run_tests
    from .reporter import print_test_report

    console.print("[bold]Running verification tests...[/bold]")
    run_tests(config)

    print_test_report(config)


@main.command(name="sp-check")
@click.option("--package", "package_name", default=None, help="Check specific package only (e.g. EHRPHRA3_PKG)")
@click.option("--engine", type=click.Choice(["regex", "ast"]), default=None,
              help="Which conversion output to check: 'regex' (converted/) or 'ast' (converted_ast/)")
@click.pass_context
def sp_check(ctx, package_name, engine):
    """Check syntax of each SP/Function individually (PARSEONLY, no data written)."""
    from pathlib import Path
    config = load_config(ctx.obj["config_path"])
    from .deployer import get_mssql_connection, check_sps_in_file

    effective_engine = engine or config.conversion.engine or "regex"
    subdir = "converted_ast" if effective_engine == "ast" else "converted"
    converted_dir = Path(config.conversion.output_dir) / subdir

    console.print("[bold]Connecting to MSSQL for SP-level syntax check...[/bold]")
    try:
        conn = get_mssql_connection(config)
    except Exception as e:
        console.print(f"[red]MSSQL connection failed: {e}[/red]")
        return

    try:
        sql_files = sorted(converted_dir.rglob("*.sql"))
        if package_name:
            sql_files = [f for f in sql_files if package_name.upper() in f.stem.upper()]

        if not sql_files:
            console.print("[yellow]No converted SQL files found.[/yellow]")
            return

        total = 0
        passed = 0
        failed_list = []

        for sql_path in sql_files:
            console.print(f"\n[bold cyan]{sql_path.stem}[/bold cyan]")
            results = check_sps_in_file(conn, sql_path)

            for sp_name, ok, err in results:
                total += 1
                if ok:
                    passed += 1
                    console.print(f"  [green]PASS[/green]  {sp_name}")
                else:
                    failed_list.append((sql_path.stem, sp_name, err))
                    console.print(f"  [red]FAIL[/red]  {sp_name}")
                    console.print(f"        [red]{err}[/red]")

        console.print(f"\n[bold]Result: {passed}/{total} passed, {len(failed_list)} failed[/bold]")
        if failed_list:
            console.print("\n[bold red]Failed SPs:[/bold red]")
            for pkg, sp, err in failed_list:
                console.print(f"  [{pkg}] {sp}: {err}")
    finally:
        conn.close()


@main.command(name="run-all")
@click.option("--dry-run", is_flag=True, help="Don't actually deploy")
@click.pass_context
def run_all(ctx, dry_run):
    """Run full pipeline: extract → analyze → convert → deploy → test."""
    config = load_config(ctx.obj["config_path"])

    console.print("[bold cyan]Running full pipeline...[/bold cyan]")

    # Step 1: Extract
    console.print("\n[bold]Step 1/5: Extract[/bold]")
    from .extractor import run_extract
    extract_result = run_extract(config)
    if extract_result.errors:
        console.print("[red]Extract failed, aborting.[/red]")
        return

    # Step 2: Analyze
    console.print("\n[bold]Step 2/5: Analyze[/bold]")
    from .analyzer import run_analyze
    analyze_result = run_analyze(config)
    if analyze_result.errors:
        console.print("[red]Analyze failed, aborting.[/red]")
        return

    # Step 3: Convert
    console.print("\n[bold]Step 3/5: Convert[/bold]")
    from .converter import run_convert
    convert_results = run_convert(config)

    # Step 4: Deploy
    console.print(f"\n[bold]Step 4/5: Deploy {'(dry-run)' if dry_run else ''}[/bold]")
    from .deployer import run_deploy
    deploy_result = run_deploy(config, dry_run=dry_run)

    # Step 5: Test
    console.print("\n[bold]Step 5/5: Test[/bold]")
    from .tester import run_tests
    test_result = run_tests(config)

    # Final summary
    console.print("\n[bold cyan]Pipeline complete![/bold cyan]")
    from .reporter import print_conversion_summary
    print_conversion_summary(config)


if __name__ == "__main__":
    main()
