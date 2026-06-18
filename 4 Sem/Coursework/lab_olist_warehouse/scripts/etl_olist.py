#!/usr/bin/env python3
"""ETL pipeline for the Olist data warehouse lab.

The script loads raw CSV files into a stage area and then transforms them into
an idempotent dimensional warehouse in SQLite.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import sqlite3
import sys
import time
from datetime import UTC, datetime
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[2]
LAB_DIR = Path(__file__).resolve().parents[1]
SQL_DIR = LAB_DIR / "sql"
DEFAULT_DATA_DIR = ROOT_DIR / "data"
DEFAULT_DB_PATH = LAB_DIR / "output" / "olist_dw.sqlite"
DEFAULT_SUMMARY_PATH = LAB_DIR / "output" / "etl_run_summary.json"

DATASETS = [
    ("olist_customers_dataset.csv", "stg_customers"),
    ("olist_geolocation_dataset.csv", "stg_geolocation"),
    ("olist_orders_dataset.csv", "stg_orders"),
    ("olist_order_items_dataset.csv", "stg_order_items"),
    ("olist_order_payments_dataset.csv", "stg_order_payments"),
    ("olist_order_reviews_dataset.csv", "stg_order_reviews"),
    ("olist_products_dataset.csv", "stg_products"),
    ("olist_sellers_dataset.csv", "stg_sellers"),
    ("product_category_name_translation.csv", "stg_product_category_translation"),
]

WAREHOUSE_TABLES = [
    "dim_date",
    "dim_location",
    "dim_order_status",
    "dim_payment_type",
    "dim_category",
    "dim_product",
    "dim_customer",
    "dim_seller",
    "fact_order_items",
    "fact_payments",
    "fact_reviews",
]


def read_sql(name: str) -> str:
    return (SQL_DIR / name).read_text(encoding="utf-8")


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    conn.execute("PRAGMA synchronous = NORMAL")
    conn.execute("PRAGMA temp_store = MEMORY")
    return conn


def execute_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(read_sql("01_stage_schema.sql"))
    conn.executescript(read_sql("02_warehouse_schema.sql"))
    conn.commit()


def normalize_row(row: dict[str, str]) -> dict[str, object]:
    normalized: dict[str, object] = {}
    for key, value in row.items():
        clean_key = key.lstrip("\ufeff")
        if value == "":
            normalized[clean_key] = None
        else:
            normalized[clean_key] = value
    return normalized


def truncate_stage(conn: sqlite3.Connection) -> None:
    for _, table in DATASETS:
        conn.execute(f"DELETE FROM {table}")
    conn.commit()


def load_csv_to_stage(conn: sqlite3.Connection, data_dir: Path) -> dict[str, int]:
    truncate_stage(conn)
    loaded_counts: dict[str, int] = {}
    now = datetime.now(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")

    for file_name, table in DATASETS:
        path = data_dir / file_name
        if not path.exists():
            raise FileNotFoundError(f"Missing source file: {path}")

        with path.open("r", encoding="utf-8-sig", newline="") as source:
            reader = csv.DictReader(source)
            if not reader.fieldnames:
                raise ValueError(f"CSV file has no header: {path}")

            columns = [column.lstrip("\ufeff") for column in reader.fieldnames]
            placeholders = ", ".join(["?"] * len(columns))
            column_sql = ", ".join(columns)
            insert_sql = f"INSERT OR REPLACE INTO {table} ({column_sql}) VALUES ({placeholders})"

            batch: list[tuple[object, ...]] = []
            count = 0
            for row in reader:
                normalized = normalize_row(row)
                batch.append(tuple(normalized.get(column) for column in columns))
                if len(batch) >= 5000:
                    conn.executemany(insert_sql, batch)
                    count += len(batch)
                    batch.clear()
            if batch:
                conn.executemany(insert_sql, batch)
                count += len(batch)

        conn.execute(
            """
            INSERT INTO etl_file_log (file_name, loaded_at, row_count, source_mtime)
            VALUES (?, ?, ?, ?)
            ON CONFLICT (file_name) DO UPDATE SET
                loaded_at = excluded.loaded_at,
                row_count = excluded.row_count,
                source_mtime = excluded.source_mtime
            """,
            (file_name, now, count, path.stat().st_mtime),
        )
        loaded_counts[table] = count
        conn.commit()

    return loaded_counts


def transform_to_warehouse(conn: sqlite3.Connection) -> None:
    conn.executescript(read_sql("03_transform_load.sql"))
    conn.commit()


def count_rows(conn: sqlite3.Connection, tables: list[str]) -> dict[str, int]:
    return {
        table: int(conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0])
        for table in tables
    }


def run_quality_checks(conn: sqlite3.Connection) -> dict[str, int]:
    checks = {
        "fact_order_items_without_customer": """
            SELECT COUNT(*) FROM fact_order_items WHERE customer_key IS NULL
        """,
        "fact_order_items_without_product": """
            SELECT COUNT(*) FROM fact_order_items WHERE product_key IS NULL
        """,
        "fact_order_items_without_seller": """
            SELECT COUNT(*) FROM fact_order_items WHERE seller_key IS NULL
        """,
        "fact_payments_without_payment_type": """
            SELECT COUNT(*) FROM fact_payments WHERE payment_type_key IS NULL
        """,
        "fact_reviews_out_of_range": """
            SELECT COUNT(*) FROM fact_reviews WHERE review_score < 1 OR review_score > 5
        """,
    }
    return {name: int(conn.execute(sql).fetchone()[0]) for name, sql in checks.items()}


def top_category_metrics(conn: sqlite3.Connection) -> list[dict[str, object]]:
    rows = conn.execute(
        """
        SELECT
            c.category_name_english,
            COUNT(*) AS order_items,
            ROUND(SUM(f.total_item_value), 2) AS total_revenue,
            ROUND(AVG(r.review_score), 2) AS avg_review_score
        FROM fact_order_items f
        JOIN dim_product p ON p.product_key = f.product_key
        JOIN dim_category c ON c.category_key = p.category_key
        LEFT JOIN fact_reviews r ON r.order_id = f.order_id
        GROUP BY c.category_name_english
        ORDER BY total_revenue DESC
        LIMIT 10
        """
    ).fetchall()
    return [
        {
            "category": row[0],
            "order_items": row[1],
            "total_revenue": row[2],
            "avg_review_score": row[3],
        }
        for row in rows
    ]


def run_etl(data_dir: Path, db_path: Path, reset: bool) -> dict[str, object]:
    if reset and db_path.exists():
        db_path.unlink()
        wal = db_path.with_suffix(db_path.suffix + "-wal")
        shm = db_path.with_suffix(db_path.suffix + "-shm")
        for sidecar in (wal, shm):
            if sidecar.exists():
                sidecar.unlink()

    started_at = datetime.now(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")
    start_time = time.perf_counter()

    with connect(db_path) as conn:
        execute_schema(conn)
        conn.execute(
            "INSERT INTO etl_run_log (started_at, status, message) VALUES (?, ?, ?)",
            (started_at, "running", "Stage and warehouse load started"),
        )
        run_id = int(conn.execute("SELECT last_insert_rowid()").fetchone()[0])
        conn.commit()

        try:
            stage_counts = load_csv_to_stage(conn, data_dir)
            transform_to_warehouse(conn)
            warehouse_counts = count_rows(conn, WAREHOUSE_TABLES)
            quality_checks = run_quality_checks(conn)
            stage_total = sum(stage_counts.values())
            warehouse_total = sum(warehouse_counts.values())
            finished_at = datetime.now(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")
            conn.execute(
                """
                UPDATE etl_run_log
                SET finished_at = ?, status = ?, stage_rows = ?, warehouse_rows = ?, message = ?
                WHERE run_id = ?
                """,
                (finished_at, "success", stage_total, warehouse_total, "ETL completed", run_id),
            )
            conn.commit()
        except Exception as exc:
            finished_at = datetime.now(UTC).isoformat(timespec="seconds").replace("+00:00", "Z")
            conn.execute(
                """
                UPDATE etl_run_log
                SET finished_at = ?, status = ?, message = ?
                WHERE run_id = ?
                """,
                (finished_at, "failed", str(exc), run_id),
            )
            conn.commit()
            raise

        return {
            "run_id": run_id,
            "started_at": started_at,
            "finished_at": finished_at,
            "duration_seconds": round(time.perf_counter() - start_time, 2),
            "database": str(db_path),
            "stage_counts": stage_counts,
            "warehouse_counts": warehouse_counts,
            "quality_checks": quality_checks,
            "top_category_metrics": top_category_metrics(conn),
        }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load Olist CSV data into a dimensional SQLite warehouse.")
    parser.add_argument("--data-dir", type=Path, default=DEFAULT_DATA_DIR, help="Directory with Olist CSV files.")
    parser.add_argument("--db", type=Path, default=DEFAULT_DB_PATH, help="Output SQLite database path.")
    parser.add_argument("--summary", type=Path, default=DEFAULT_SUMMARY_PATH, help="Where to write JSON run summary.")
    parser.add_argument("--reset", action="store_true", help="Delete the existing database before loading.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    summary = run_etl(args.data_dir.resolve(), args.db.resolve(), args.reset)
    args.summary.parent.mkdir(parents=True, exist_ok=True)
    args.summary.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
