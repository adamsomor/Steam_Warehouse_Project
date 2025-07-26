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
- **Process:** A series of stored procedures parse and extract structured data from raw JSON into normalized dimension and fact tables in the `silver` schema.
- **Key Tables:**
  - Dimension tables: `dim_categories`, `dim_developers`, `dim_genres`, `dim_publishers`, `dim_rating_agencies`, `review_authors`, `games_master`
  - Fact tables linking games to categories, developers, genres, publishers, ratings, platforms, reviews, and review statistics.
- **Mechanism:** Multiple stored procedures run sequentially or individually to load and update these tables, handling nested JSON and ensuring unique keys.

## 3. Gold Layer (Curated Analytical Model)
- **Source:** Cleaned and structured data from the `silver` schema
- **Process:** Single stored procedure `public.build_gold_tables()` builds star schema-style dimensional and fact tables in the `gold` schema optimized for querying and analytics.
- **Key Steps:**
  - Drop and recreate gold schema tables.
  - Create dimensional tables (`dim_games`, `dim_platforms`, `dim_genres`, `dim_categories`, `dim_publishers`, `dim_developers`, `dim_rating_agencies`, `dim_review_authors`) by selecting from silver.
  - Create fact tables (`fact_game_platforms`, `fact_game_genres`, `fact_game_categories`, `fact_game_publishers`, `fact_game_developers`, `fact_game_ratings`, `fact_reviews_agg`, `fact_reviews`) by joining or aggregating silver tables.
  - Define primary keys and foreign keys for referential integrity.
  - Add indexes to optimize query performance.

---
