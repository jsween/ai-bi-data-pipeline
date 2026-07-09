"""
run_quality_checks.py

Runs every SQL quality check under sql/quality/ against BigQuery and reports
pass/fail. Each check file follows the project convention stated in its own
header comment: "All checks should return 0 or TRUE to pass."

Check classification:
  - If the comment immediately above a check contains the word "eyeball",
    it's treated as informational only (never pass/fail) - these checks were
    written for a human to glance at (e.g. SELECT DISTINCT state), not to be
    machine-judged.
  - A query returning zero rows is PASS (covers duplicate/orphan checks
    written as "... HAVING COUNT(*) > 1" or "LEFT JOIN ... WHERE x IS NULL",
    which intentionally return nothing when the data is healthy).
  - A single-row result containing a boolean column (e.g. counts_match) is
    PASS only if every boolean value in that row is TRUE. Non-boolean
    columns in the same row (raw counts, dates) are context, not judged.
  - A single-row, all-numeric result is PASS only if every value is 0
    (covers "SELECT COUNT(*) AS null_x ..." style checks).
  - A single-row, all-numeric, non-zero result that isn't covered by the
    above (e.g. a plain informational row count) doesn't fit the 0-or-TRUE
    convention - it's logged as INFO rather than guessed at.
  - Multiple rows returned outside of an "eyeball" check are treated as
    FAIL (this is what catches duplicate/orphan rows when they exist).

Usage:
    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
    python pipelines/quality/run_quality_checks.py
"""

import glob
import os
import sys

from google.cloud import bigquery

# ── Configuration ──────────────────────────────────────────────────────────────

PROJECT_ID = "ai-bi-pipeline"
QUALITY_SQL_GLOB = "sql/quality/**/*.sql"


# ── File Parsing ────────────────────────────────────────────────────────────────

def parse_checks(sql_text):
    """
    Splits a quality-check file into (comment, statement) pairs. Each
    statement is assumed to be terminated by a ';' at the end of a line,
    matching the convention used throughout this project's SQL files.
    """
    checks = []
    comment_lines = []
    statement_lines = []

    for line in sql_text.splitlines():
        stripped = line.strip()

        if not stripped:
            continue

        if stripped.startswith("--"):
            comment_lines.append(stripped)
            continue

        statement_lines.append(line)

        if stripped.endswith(";"):
            checks.append({
                "comment": "\n".join(comment_lines),
                "statement": "\n".join(statement_lines).strip(),
            })
            comment_lines = []
            statement_lines = []

    return checks


# ── Check Classification ────────────────────────────────────────────────────────

def classify(comment, rows):
    """Applies the project's "0 or TRUE to pass" convention to a check's result."""

    if "eyeball" in comment.lower():
        return "INFO"

    if len(rows) == 0:
        return "PASS"

    if len(rows) == 1:
        row = rows[0]
        bool_values = [v for v in row.values() if isinstance(v, bool)]
        if bool_values:
            return "PASS" if all(bool_values) else "FAIL"

        numeric_values = [v for v in row.values() if isinstance(v, (int, float))]
        if numeric_values:
            return "PASS" if all(v == 0 for v in numeric_values) else "FAIL"

        return "INFO"

    # Multiple rows outside an "eyeball" check - almost always duplicates
    # or orphaned keys that were found
    return "FAIL"


# ── Main ─────────────────────────────────────────────────────────────────────────

def run_all_checks():
    client = bigquery.Client(project=PROJECT_ID)

    sql_files = sorted(glob.glob(QUALITY_SQL_GLOB, recursive=True))
    if not sql_files:
        print(f"No quality check files found matching {QUALITY_SQL_GLOB}")
        sys.exit(1)

    counts = {"PASS": 0, "FAIL": 0, "INFO": 0}

    for filename in sql_files:
        with open(filename, "r") as f:
            checks = parse_checks(f.read())

        for i, check in enumerate(checks, start=1):
            query_job = client.query(check["statement"])
            rows = [dict(row) for row in query_job.result()]

            status = classify(check["comment"], rows)
            counts[status] += 1

            print(f"[{status}] {filename} - check #{i}")
            if status in ("FAIL", "INFO") and rows:
                for row in rows:
                    print(f"    {row}")

    print("-" * 60)
    print(
        f"Quality checks complete: {counts['PASS']} passed, "
        f"{counts['FAIL']} failed, {counts['INFO']} informational"
    )

    if counts["FAIL"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    creds = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not creds:
        raise EnvironmentError(
            "GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.\n"
            "Run: export GOOGLE_APPLICATION_CREDENTIALS='/path/to/key.json'"
        )

    run_all_checks()