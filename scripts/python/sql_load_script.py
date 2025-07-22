# ====================================================
# 				PYTHON SCRIPT
# 	             LOAD TO SQL
# ====================================================
# Before executing:
#            BATCH_ROOT = Path("")
#            "dbname": "",
#            "user": "",
#            "password": "",
#            "host": "",
#            "port": 
#
# To execute run:
# 		python sql_load_script.py START_NUM END_NUM
#
# EXAMPLES:
# python sql_load_script.py 1 5         # Loads batches 1–5
# python sql_load_script.py all         # Loads everything (up to MAX_BATCHES)
# python sql_load_script.py 30 30       # Only loads batch_0030
# ====================================================


import psycopg2
import json
import os
import sys
from pathlib import Path

# === CONFIGURATION ===
BATCH_ROOT = Path("") # Set your path
DB_PARAMS = {
    "dbname": "asd",
    "user": "asd",
    "password": "asd",
    "host": "asd",
    "port": 1234
}
MAX_BATCHES = 9999  # safety cap

# === PARSE ARGUMENTS ===
if len(sys.argv) == 2 and sys.argv[1].lower() == "all":
    start_batch = 1
    end_batch = MAX_BATCHES
elif len(sys.argv) == 3:
    start_batch = int(sys.argv[1])
    end_batch = int(sys.argv[2])
else:
    print("Usage:\n  python sql_load_script.py all\n  python sql_load_script.py <start> <end>")
    sys.exit(1)

# === CONNECT TO DATABASE ===
conn = psycopg2.connect(**DB_PARAMS)
cur = conn.cursor()

# === CREATE SCHEMA IF NOT EXISTS ===
cur.execute("CREATE SCHEMA IF NOT EXISTS bronze") # creates schema called bronze, FYI the schema should already exist if you run database_init file

# === ENSURE TABLES EXIST ===
cur.execute("""
CREATE TABLE IF NOT EXISTS bronze.steam_app_details (
    steam_appid INTEGER PRIMARY KEY,
    raw_json JSONB NOT NULL
)
""") # creates table called games_raw

cur.execute("""
CREATE TABLE IF NOT EXISTS bronze.load_log (
    id SERIAL PRIMARY KEY,
    steam_appid INTEGER,
    batch_num INTEGER,
    file_name TEXT,
    status TEXT,  -- 'inserted', 'skipped', 'error'
    error_message TEXT,
    inserted_at TIMESTAMPTZ DEFAULT NOW()
)
""") #  creates table called load_log

# === LOOP THROUGH BATCHES ===
for batch_num in range(start_batch, end_batch + 1):
    batch_dir = BATCH_ROOT / f"batch_{batch_num:04d}"
    if not batch_dir.exists():
        print(f"Batch {batch_dir} does not exist. Skipping.")
        continue

    print(f"Loading batch: {batch_dir}")
    json_files = sorted([f for f in batch_dir.iterdir() if f.suffix == ".json"])

    for file_path in json_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                raw_json = json.load(f)
                appid_key = next(iter(raw_json))
                game_info = raw_json[appid_key]

                if not game_info.get("success", False):
                    cur.execute("""
                        INSERT INTO bronze.load_log (steam_appid, batch_num, file_name, status, error_message)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (None, batch_num, file_path.name, 'skipped', 'success=false'))
                    conn.commit()
                    print(f"Skipped (no success): {file_path.name}")
                    continue

                data = game_info["data"]
                steam_appid = data["steam_appid"]

                try:
                    cur.execute("""
                        INSERT INTO bronze.steam_app_details (steam_appid, raw_json)
                        VALUES (%s, %s)
                        ON CONFLICT (steam_appid) DO NOTHING
                    """, (steam_appid, json.dumps(data)))

                    cur.execute("""
                        INSERT INTO bronze.load_log (steam_appid, batch_num, file_name, status, error_message)
                        VALUES (%s, %s, %s, %s, NULL)
                    """, (steam_appid, batch_num, file_path.name, 'inserted'))
                    conn.commit()
                    print(f"Inserted: {steam_appid} from {file_path.name}")

                except psycopg2.Error as e:
                    conn.rollback()
                    cur.execute("""
                        INSERT INTO bronze.load_log (steam_appid, batch_num, file_name, status, error_message)
                        VALUES (%s, %s, %s, %s, %s)
                    """, (steam_appid, batch_num, file_path.name, 'error', str(e)))
                    conn.commit()
                    print(f"Failed to insert {steam_appid}: {e}")

        except Exception as e:
            conn.rollback()
            cur.execute("""
                INSERT INTO bronze.load_log (steam_appid, batch_num, file_name, status, error_message)
                VALUES (%s, %s, %s, %s, %s)
            """, (None, batch_num, file_path.name, 'error', str(e)))
            conn.commit()
            print(f"Error reading {file_path.name}: {e}")


# === FINALIZE ===
conn.commit()
cur.close()
conn.close()
print("All selected batches loaded.")
