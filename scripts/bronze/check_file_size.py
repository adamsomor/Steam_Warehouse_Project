# ====================================================
# 				PYTHON SCRIPT
# 			   CHECK FILE SIZE
# ====================================================
# Before executing:
#           Set BATCH_ROOT = Path("SET YOUR ROOT")
#           SIZE_LIMIT_MB = 
#
# To execute run:
# 		python check_file_size.py
# ====================================================

import os
from pathlib import Path

# === CONFIGURATION ===
BATCH_ROOT = Path("") # Set your path
SIZE_LIMIT_MB =   # Size limit in megabytes

# === SCAN FUNCTION ===
def find_large_jsons(batch_root, size_limit_mb):
    large_files = []
    for batch_dir in sorted(batch_root.glob("batch_*")):
        for file_path in batch_dir.glob("*.json"):
            size_mb = file_path.stat().st_size / (1024 * 1024)
            if size_mb > size_limit_mb:
                large_files.append((file_path, round(size_mb, 2)))

    return large_files

# === RUN ===
if __name__ == "__main__":
    oversized = find_large_jsons(BATCH_ROOT, SIZE_LIMIT_MB)
    if oversized:
        print(f"Found {len(oversized)} oversized files (> {SIZE_LIMIT_MB} MB):\n")
        for path, size in oversized:
            print(f"{path} — {size} MB")
    else:
        print("No files exceed the size limit.")
