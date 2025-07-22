# ====================================================
# 				PYTHON SCRIPT
# 			    JSON CLEANER
# ====================================================
# Before executing:
#            files_to_clean = [
#                "YOUR PATH GOES HERE",
#           
#            keys_to_remove = [
#                "screenshots",
#                "movies",
#                "background"
#                "background_raw",
#            ]
#
# To execute run:
# 		json_cleaner.py
# ====================================================


import json
from pathlib import Path

print("starting")
# === FILES TO CLEAN ===
files_to_clean = [
    "", # insert your path
]

# === KEYS TO REMOVE FROM 'data' FIELD ===
keys_to_remove = [ # insert JSON keys to be removed e.g. screenshots, movies, background . . .
    "screenshots",
    "movies",
    "background",
    "background_raw",
]

# === PROCESS EACH FILE ===
for file_path in files_to_clean:
    file_path = Path(file_path)
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            raw_json = json.load(f)

        appid_key = next(iter(raw_json))
        game_info = raw_json[appid_key]

        if not game_info.get("success", False):
            print(f"[SKIPPED] {file_path.name} — success=false")
            continue

        data = game_info.get("data", {})

        removed_keys = []
        for key in keys_to_remove:
            if key in data:
                del data[key]
                removed_keys.append(key)

        # Save cleaned JSON (overwrite original)
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump({appid_key: game_info}, f, ensure_ascii=False, separators=(",", ":"))

        print(f"[CLEANED] {file_path.name} — removed: {', '.join(removed_keys)}")

    except Exception as e:
        print(f"[ERROR] {file_path.name}: {e}")
