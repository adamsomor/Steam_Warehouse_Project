# Bronze Layer Data Catalogue

---

## Table: `bronze.steam_app_details`

| Column Name   | Data Type |  PK  | FK  | Description                                                                 |
|---------------|-----------|-----|-----|-----------------------------------------------------------------------------|
| `steam_appid` | INTEGER   | PK  |     | Unique Steam application ID. Primary key.                                  |
| `raw_json`    | JSONB     |     |     | Raw, parsed game metadata from the Steam API (`"data"` field of the JSON). |

---

## Table: `bronze.load_log`

| Column Name     | Data Type   |  PK  | FK  | Description                                                                 |
|-----------------|-------------|-----|-----|-----------------------------------------------------------------------------|
| `id`            | SERIAL      | PK  |     | Unique identifier for each log entry.                                       |
| `steam_appid`   | INTEGER     |     |     | Steam app ID being processed. May be NULL if file failed before parsing.   |
| `batch_num`     | INTEGER     |     |     | Batch number indicating which file group the entry came from.              |
| `file_name`     | TEXT        |     |     | Filename of the JSON file processed.                                       |
| `status`        | TEXT        |     |     | Status of the operation: `'inserted'`, `'skipped'`, or `'error'`.          |
| `error_message` | TEXT        |     |     | Error details if any (e.g. parse failure, constraint violation, etc.).     |
| `inserted_at`   | TIMESTAMPTZ |     |     | Timestamp of when this log entry was created (defaults to `NOW()`).        |

---

## Relationships

- `load_log.steam_appid` may reference `steam_app_details.steam_appid` — no enforced foreign key constraint (nullable for skipped or error rows).

---
