# Data Flow Overview

---

## 1. Bronze Layer (Raw Data Ingestion)
- **Source:** JSON files (Steam app details batches)
- **Process:** Python script loads each batch of JSON files into the `bronze.steam_app_details` table.
- **Tables:**
  - `bronze.steam_app_details` (stores raw JSON data for each game)
  - `bronze.load_log` (tracks success, skips, or errors during loading)

## 2. Silver Layer (Data Transformation & Structuring)
- **Source:** Data from `bronze.steam_app_details`
- **Process:** A series of stored procedures parse and extract structured data from raw JSON into normalized dimension, hub, bridge, fact, and satellite tables in the `silver` schema.
- **Key Tables:**
  - **Dimension tables:**  
    `dim_category`, `dim_developer`, `dim_genre`, `dim_publisher`, `dim_agency`  
  - **Hub (entity) tables:**  
    `hub_game`, `hub_author`  
  - **Bridge (factless‑fact) tables:**  
    `bridge_category`, `bridge_developer`, `bridge_genre`, `bridge_publisher`, `bridge_platform`  
  - **Fact tables:**  
    `fct_rating`, `fct_review_stat`  
  - **Satellite tables (large/descriptive attributes):**  
    `sat_review_text`
- **Mechanism:** A pipeline of stored procedures handles:
  1. **Extraction** from the raw JSON
  2. **Key generation** for hubs and dimensions (ensuring uniqueness)  
  3. **Bridge population** to model M‑N relationships (game ↔ category/developer/genre/publisher/platform)  
  4. **Fact loading** for ratings and review statistics  
  5. **Satellite loading** for full review text  
- Each procedure can be run independently or chained, and updates only the relevant tables to support incremental loads and easy re‑runs.

## 3. Gold Layer (Curated Analytical Model)
- **Source:** Cleaned and structured data from the `silver` schema
- **Process:** Single stored procedure `public.build_gold_tables()` builds star schema-style dimensional and fact tables in the `gold` schema optimized for querying and analytics.
- **Key Steps:**
  - Drop and recreate gold schema tables.
  - Create dimensional tables (`dim_games`, `dim_platforms`, `dim_genre`, `dim_category`, `dim_publisher`, `dim_developer`, `dim_agency`, `dim_hub_author`) by selecting from silver.
  - Create fact tables (`fact_bridge_platform`, `fact_bridge_genre`, `fact_bridge_category`, `fact_bridge_publisher`, `fact_bridge_developer`, `fact_fct_rating`, `fact_reviews_agg`, `fact_reviews`) by joining or aggregating silver tables.
  - Define primary keys and foreign keys for referential integrity.
  - Add indexes to optimize query performance.

---
