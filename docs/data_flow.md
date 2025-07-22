        Steam API (JSON files: game details, reviews, authors, pricing)
        └──▶ 2.1 Source
            └── JSON auto-fetched (~20,000 files)
                └── Organized into ~300-file batches
    
                    ▼
            2.2 Ingestion (Bronze Layer)
            └── Python ETL Script
                ├── Check file size (limit: 256 MiB for jsonb)
                ├── Read & batch 300 JSON files
                ├── Insert raw data → `bronze.steam_app_details`
                └── Log status/errors → `bronze.load_log`
    
                    ▼
            2.3 Transformation (Silver Layer)
            ├── JSON Normalization
            │   ├── Core: `silver.games_master`
            │   ├── Dimensions:
            │   │   ├── `dim_publishers`
            │   │   ├── `dim_categories`
            │   │   ├── `dim_genres`
            │   │   ├── `dim_developers`
            │   │   └── `dim_rating_agencies`
            │   └── Bridges / Facts:
            │       ├── `game_publishers`
            │       ├── `game_categories`
            │       ├── `game_genres`
            │       ├── `game_developers`
            │       ├── `game_ratings`
            │       ├── `game_platforms`
            │       ├── `review_authors`
            │       ├── `game_review_stats`
            │       └── `game_reviews`
            ├── Data Quality Checks
            │   ├── Null detection
            │   ├── Duplicate checks
            │   ├── Value-range validation
            │   └── Orphaned foreign key detection
            └── Integrity Enforcement
                ├── Deduplication
                ├── Foreign key validation
                └── Controlled truncate-reload
    
                    ▼
            2.4 Materialization (Gold Layer)
            ├── Denormalization of bridge/dimension data
            ├── Aggregations for KPIs
            │   ├── Review stats → `gold.review_summary`
            │   └── Game enrichment → `gold.games_enriched`
            └── Output:
                ├── Fast dashboard queries
                ├── BI tooling
                └── Reporting/exports
