#!/usr/bin/env python3
"""
SQLGlot transpiler script for Emacs integration.

This script provides a command-line interface for SQLGlot operations
including transpilation between dialects and SQL formatting.
"""

import sys
import argparse
import json
from typing import Optional


try:
    import sqlglot
except ImportError:
    print(
        "Error: sqlglot package not installed. Run: pip install sqlglot",
        file=sys.stderr,
    )
    sys.exit(1)


def transpile_sql(
    sql: str, read_dialect: Optional[str], write_dialect: Optional[str], pretty: bool = False
) -> str:
    """Transpile SQL from one dialect to another with optional pretty printing."""
    try:
        result = sqlglot.transpile(sql, read=read_dialect, write=write_dialect, pretty=pretty)
        if result:
            return result[0]
        else:
            raise ValueError("No result from transpilation")
    except Exception as e:
        operation = "formatting" if pretty else "transpilation"
        raise RuntimeError(f"SQL {operation} failed: {e}")


def format_sql(sql: str, read_dialect: Optional[str] = None, write_dialect: Optional[str] = None) -> str:
    """Format/pretty-print SQL with optional read_dialect and write_dialect."""
    return transpile_sql(sql, read_dialect, write_dialect, pretty=True)


def get_version() -> str:
    """Get SQLGlot version."""
    return getattr(sqlglot, "__version__", "unknown")


def list_dialects() -> list:
    """List all supported dialects."""
    # Get dialects from sqlglot.dialects module
    from sqlglot import dialects

    dialect_names: list[str] = []

    for attr_name in dir(dialects):
        attr = getattr(dialects, attr_name)
        if (
            hasattr(attr, "__module__")
            and attr.__module__
            and "dialects" in attr.__module__
            and hasattr(attr, "Dialect")
            and attr_name.lower() not in ["dialect", "dialects"]
        ):
            dialect_names.append(attr_name.lower())

    # Add common aliases and ensure standard ones are included
    standard_dialects: list[str] = [
        "athena",
        "bigquery",
        "clickhouse",
        "databricks",
        "doris",
        "dremio",
        "drill",
        "druid",
        "duckdb",
        "dune",
        "fabric",
        "hive",
        "materialize",
        "mysql",
        "oracle",
        "postgres",
        "postgresql",
        "presto",
        "prql",
        "redshift",
        "risingwave",
        "snowflake",
        "spark",
        "spark2",
        "sqlite",
        "starrocks",
        "tableau",
        "teradata",
        "trino",
        "tsql",
        "exasol",
    ]

    # Combine and deduplicate
    all_dialects: set[str] = set(dialect_names + standard_dialects)

    return sorted(all_dialects)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="SQLGlot transpiler for Emacs integration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Transpile command
    transpile_parser = subparsers.add_parser(
        "transpile", help="Transpile SQL between dialects"
    )
    transpile_parser.add_argument("--read", help="Source dialect (optional)")
    transpile_parser.add_argument("--write", help="Target dialect (optional)")
    transpile_parser.add_argument(
        "--sql", help="SQL to transpile (if not provided, reads from stdin)"
    )

    # Format command
    format_parser = subparsers.add_parser("format", help="Format/pretty-print SQL")
    format_parser.add_argument("--dialect", help="SQL dialect (optional)")
    format_parser.add_argument("--read", help="Source dialect (alias for --dialect)")
    format_parser.add_argument("--write", help="Target dialect (alias for --dialect)")
    format_parser.add_argument(
        "--sql", help="SQL to format (if not provided, reads from stdin)"
    )

    # Version command
    subparsers.add_parser("version", help="Show SQLGlot version")

    # Dialects command
    subparsers.add_parser("dialects", help="List supported dialects")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    try:
        if args.command == "version":
            print(get_version())

        elif args.command == "dialects":
            dialects = list_dialects()
            print(json.dumps(dialects, indent=2))

        elif args.command == "transpile":
            if args.sql:
                sql = args.sql
            else:
                sql = sys.stdin.read()

            if not sql.strip():
                print("Error: No SQL provided", file=sys.stderr)
                sys.exit(1)

            result = transpile_sql(sql, args.read, args.write)
            print(result, end="")

        elif args.command == "format":
            if args.sql:
                sql = args.sql
            else:
                sql = sys.stdin.read()

            if not sql.strip():
                print("Error: No SQL provided", file=sys.stderr)
                sys.exit(1)

            # Use read and write dialects for formatting
            result: str = format_sql(sql, args.read or args.dialect, args.write or args.dialect)
            print(result, end="")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
