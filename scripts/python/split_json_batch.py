# ====================================================
# 				PYTHON SCRIPT
# 	             SPLIT JSONs
# ====================================================
# Before executing:
#           SOURCE_DIR = Path("")
#           TARGET_DIR = Path(")
#           LOG_FILE = TARGET_DIR / ""
#           BATCH_SIZE =
#
# To execute run:
# 		python split_json_batch.py
# ====================================================


import os
import shutil
from pathlib import Path
from math import ceil
import re

# === CONFIGURATION ===
SOURCE_DIR = Path("") # source of data
TARGET_DIR = Path("") # where to put the data
LOG_FILE = TARGET_DIR / "" # name yout log
BATCH_SIZE = 300  # adjust as needed

# === TEST MODE ===
TEST_MODE = False            # Set to False when running full batch
MAX_TEST_BATCHES = 10       # How many batches to process in test mode

# === CREATE TARGET DIR AND LOG ===
TARGET_DIR.mkdir(parents=True, exist_ok=True)
log = open(LOG_FILE, "w", encoding="utf-8")

# === COLLECT AND SORT JSON FILE PATHS ===
json_files = []

for root, dirs, files in os.walk(SOURCE_DIR):
    for file in files:
        if file.endswith(".json"):
            full_path = Path(root) / file
            json_files.append(full_path)

# Sort files numerically by number prefix in parent directory or filename
def extract_number(path: Path):
    match = re.search(r'(\d+)_data', str(path.parent.name)) or re.search(r'(\d+)_data', path.name)
    return int(match.group(1)) if match else float('inf')

json_files.sort(key=extract_number)

# Calculate total batches
total_files = len(json_files)
total_batches = ceil(total_files / BATCH_SIZE)

log.write(f"Total files: {total_files}\n")
log.write(f"Batch size: {BATCH_SIZE}\n")
log.write(f"Total batches: {total_batches}\n\n")

# Apply test mode limit on batches
batches_to_process = total_batches if not TEST_MODE else min(total_batches, MAX_TEST_BATCHES)

# === SPLIT AND COPY FILES INTO BATCHES ===
for i in range(batches_to_process):
    batch_files = json_files[i*BATCH_SIZE:(i+1)*BATCH_SIZE]
    batch_dir = TARGET_DIR / f"batch_{i+1:04d}"
    batch_dir.mkdir(parents=True, exist_ok=True)

    log.write(f"Batch {i+1:04d}:\n")
    for file_path in batch_files:
        target_path = batch_dir / file_path.name
        shutil.copy2(file_path, target_path)
        log.write(f"  {file_path} -> {target_path}\n")
    log.write("\n")
    print(f"Created batch_{i+1:04d} with {len(batch_files)} files.")

log.close()
print("All batches created and logged.")
