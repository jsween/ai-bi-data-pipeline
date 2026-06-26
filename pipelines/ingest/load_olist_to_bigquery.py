"""
load_olist_to_bigquery.py

Loads all 9 Olist CSV files from Google Cloud Storage into BigQuery raw_olist dataset.
Each CSV becomes one table in raw_olist, named after the source file.

Some files (e.g. order reviews) contain free-text fields with unescaped quotes,
commas, and special characters. These are handled with a lenient load config.

Usage:
    Set the GOOGLE_APPLICATION_CREDENTIALS environment variable to your
    service account key path before running:

    export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
    python pipelines/ingest/load_olist_to_bigquery.py
"""

import os
from google.cloud import bigquery

# ── Configuration ──────────────────────────────────────────────────────────────

PROJECT_ID  = "ai-bi-pipeline"
DATASET_ID  = "raw_olist"
BUCKET_NAME = "ai-bi-pipeline-raw-brazilian-ecomm-data"
GCS_PREFIX  = "raw/olist"

# Maps GCS filename → BigQuery table name
OLIST_FILES = {
    "olist_customers_dataset.csv":              "customers",
    "olist_geolocation_dataset.csv":            "geolocation",
    "olist_order_items_dataset.csv":            "order_items",
    "olist_order_payments_dataset.csv":         "order_payments",
    "olist_order_reviews_dataset.csv":          "order_reviews",
    "olist_orders_dataset.csv":                 "orders",
    "olist_products_dataset.csv":               "products",
    "olist_sellers_dataset.csv":                "sellers",
    "product_category_name_translation.csv":    "product_category_name_translation",
}

# Files with dirty free-text fields that need relaxed CSV parsing.
# The reviews file contains customer comments in Portuguese with unescaped
# quotes and special characters that break standard CSV parsing.
LENIENT_FILES = {
    "olist_order_reviews_dataset.csv",
}

# ── Load Job Configs ────────────────────────────────────────────────────────────

def make_standard_load_job_config():
    """
    Standard config for well-structured CSV files.
    Strict parsing — will fail fast if unexpected characters are encountered.
    """
    return bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )


def make_lenient_load_job_config():
    """
    Lenient config for files with dirty free-text fields (e.g. order reviews).
    Allows quoted newlines, jagged rows, and up to 1000 bad records.
    Bad records are skipped rather than failing the entire load job.
    """
    return bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        allow_quoted_newlines=True,   # handles newlines embedded inside quoted fields
        allow_jagged_rows=True,       # handles rows with fewer columns than expected
        max_bad_records=1000,         # skip up to 1000 malformed rows instead of failing
    )


# ── Main Ingestion ──────────────────────────────────────────────────────────────

def load_olist_files():
    """Loads each Olist CSV from GCS into its corresponding BigQuery table."""

    client = bigquery.Client(project=PROJECT_ID)

    print(f"\nStarting Olist ingestion into {PROJECT_ID}.{DATASET_ID}\n")
    print("-" * 60)

    success_count = 0
    error_count   = 0

    for filename, table_name in OLIST_FILES.items():

        gcs_uri   = f"gs://{BUCKET_NAME}/{GCS_PREFIX}/{filename}"
        table_ref = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

        # Select the appropriate config based on file type
        if filename in LENIENT_FILES:
            job_config  = make_lenient_load_job_config()
            config_note = "(lenient parsing)"
        else:
            job_config  = make_standard_load_job_config()
            config_note = "(standard parsing)"

        print(f"Loading: {filename} {config_note}")
        print(f"  → {table_ref}")

        try:
            load_job = client.load_table_from_uri(
                gcs_uri,
                table_ref,
                job_config=job_config,
            )
            load_job.result()  # wait for job to complete

            # Confirm row count after load
            table     = client.get_table(table_ref)
            row_count = table.num_rows

            print(f"  ✓ Done — {row_count:,} rows loaded\n")
            success_count += 1

        except Exception as e:
            print(f"  ✗ Error loading {filename}: {e}\n")
            error_count += 1

    print("-" * 60)
    print(f"Ingestion complete: {success_count} succeeded, {error_count} failed\n")


# ── Entry Point ─────────────────────────────────────────────────────────────────

if __name__ == "__main__":

    # Verify credentials are set before attempting any API calls
    creds = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not creds:
        raise EnvironmentError(
            "GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.\n"
            "Run: export GOOGLE_APPLICATION_CREDENTIALS='/path/to/key.json'"
        )

    load_olist_files()