"""Load the event log into SQLite, create the views and run every query in sql/.

Each query's result is saved to outputs/<query name>.csv, and the run time of
each query is printed so slow ones are easy to spot.
"""
import sqlite3
import time
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data" / "process.db"
CSV = ROOT / "data" / "process_events.csv.gz"
SQL_DIR = ROOT / "sql"
OUT_DIR = ROOT / "outputs"


def load(con):
    """Load the ~500k-row log in chunks so memory stays flat as the data grows."""
    con.execute("DROP TABLE IF EXISTS process_events")
    rows = 0
    for chunk in pd.read_csv(CSV, chunksize=100_000):
        chunk.to_sql("process_events", con, if_exists="append", index=False)
        rows += len(chunk)
    # Every query filters on Stage or groups/partitions by OrderID, so index both.
    con.execute("CREATE INDEX idx_events_order_stage ON process_events (OrderID, Stage)")
    con.execute("CREATE INDEX idx_events_stage ON process_events (Stage)")
    con.commit()
    return rows


def main():
    OUT_DIR.mkdir(exist_ok=True)
    DB.unlink(missing_ok=True)
    with sqlite3.connect(DB) as con:
        start = time.perf_counter()
        rows = load(con)
        print(f"Loaded {rows:,} rows in {time.perf_counter() - start:.1f}s\n")
        con.executescript((SQL_DIR / "00_views.sql").read_text(encoding="utf-8"))

        for path in sorted(SQL_DIR.glob("*.sql")):
            if path.name.startswith("00_"):
                continue
            start = time.perf_counter()
            result = pd.read_sql_query(path.read_text(encoding="utf-8"), con)
            result.to_csv(OUT_DIR / f"{path.stem}.csv", index=False, lineterminator="\n")
            print(f"{path.name:<36} {len(result):>5} rows  {time.perf_counter() - start:5.1f}s")
            if len(result) <= 12:
                print(result.to_string(index=False), "\n")


if __name__ == "__main__":
    main()
