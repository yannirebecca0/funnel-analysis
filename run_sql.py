"""Run the SQL files in sql/ in numeric order against data/processed/funnel.duckdb.

Usage: python run_sql.py [--raw PATH] [--db PATH]
"""
import argparse
import pathlib
import time

import duckdb

DEFAULT_RAW = "data/raw/2019-Oct.csv.gz"

parser = argparse.ArgumentParser()
parser.add_argument("--raw", default=DEFAULT_RAW, help="source CSV (gzip ok)")
parser.add_argument("--db", default="data/processed/funnel.duckdb")
args = parser.parse_args()

con = duckdb.connect(args.db)
con.execute("SET memory_limit = '5GB'")
con.execute("SET preserve_insertion_order = true")
for path in sorted(pathlib.Path("sql").glob("[0-9][0-9]_*.sql")):
    start = time.time()
    con.execute(path.read_text().replace(DEFAULT_RAW, args.raw))
    print(f"{path.name}: {time.time() - start:.0f}s")
con.close()
