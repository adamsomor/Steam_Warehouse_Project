    Steam API (~20,000 JSON files)
    └──▶ Pre-processed into 300-file batches
        └──▶ Ingestion Pipeline (Python ETL)
            └──▶ Bronze Layer
                ├── raw JSON → `bronze.steam_app_details`
                └── load logs → `bronze.load_log`
                    └── [✓] Error handling
                    └── [✓] Batch tracking

                ▼
        Transformation Process
        └──▶ Silver Layer (Normalized, Validated)
            ├── Fact Tables
            │   └── `silver.games_master`, `silver.game_reviews`, etc.
            ├── Dimension Tables
            │   └── `dim_publishers`, `dim_genres`, `dim_developers`, ...
            └── Bridge Tables
                └── `game_genres`, `game_developers`, `game_platforms`, ...

                ▼
        Aggregation & Denormalization
        └──▶ Gold Layer (Analytics-Ready)
            ├── `gold.games_enriched`
            │   └── arrays of genres, platforms, devs, etc.
            └── `gold.review_summary`
                └── review counts, avg scores, latest review

                ▼
        Output & Consumption
        ├── Dashboards / BI Tools
        ├── Ad-hoc SQL Queries
        └── Reporting & Exports
