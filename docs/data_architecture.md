# Data Architecture

The Steam API ingestion pipeline is organised into these main stages:
- Data collecting
- Pre‑processing
- Batching
- Bronze layer (staging)
- Silver layer (relational)
- Gold layer (semantic)

---

## Overview

- **Source**  
  • ~20 000 JSON files (Steam API “app details” payloads)  
- **Destination**  
  • PostgreSQL database  
  • Schemas: `bronze` (raw), `silver` (cleaned/relational), `gold` (BI ready)

---

## Pre‑processing & Validation

1. **File‑size check**  
   - PostgreSQL `JSONB` limit ≈ 250 MiB  
2. **Trim oversized files**  
   - Strip out large blobs (e.g. screenshots, videos, background, etc.)  
3. **Quality gate**  
   - Verify each payload’s `"success": true` flag before loading

---

## Batching

- **Batch size**: ~300 JSON files per folder  
- **Naming**: `batch_0001/`, `batch_0002/`, …  
- **Purpose**:  
  1. Avoid oversized transactions  
  2. Parallelise or retry smaller units  
  3. Maintain load‐tracking granularity

---

## Bronze (Staging) Layer

Inserts raw data in batches. It further keeps a track of each batch insertion in a `load_log` table.

---

## Silver (Cleansed / Relational) Layer

Transforms raw JSONB into normalised, query‐ready tables in schema `silver`. Rebuilt end‑to‑end via one stored procedure (drops & recreates in dependency order).

- Indexes on all FK columns

- Dimensions are lookup tables
- Hub ensure a single source of truth
- Facts store numeric measures for analysis
- Bridges model pure M‑N relationships without measures
- Satellites hold large text attributes

---

## Gold (Semantic) Layer

The Gold layer builds on Silver’s cleaned data to produce analysis‑ready tables.


---

See more in data_flow.md and data_catalogue.md
