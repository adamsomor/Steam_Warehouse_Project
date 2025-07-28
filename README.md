# Data Warehouse Project
This is a personal project developed to explore data engineering practices using real-world data from the Steam API.  
It serves as a hands-on self-study in building reliable, auditable data pipelines.  
It demonstrates:
  - Scalable batch ingestion of large semi-structured datasets: That is ~20,000 JSON files.
  - Application of the Medallion Architecture: From Bronze -> Silver -> Gold
  - Robust data validation, referential integrity, and ETL workflows that produce clean, normalsied, query-optimsied tables
  - Final outputs designed for BI tools (Tableau, Power BI)  

![Data Model](docs/gold.model.png)

### Privacy & Ethics
- Review authors' SteamIDs are handled strictly for referential integrity.  
- No personal data beyond public Steam review content is processed.  

### Notice
- The current project is still to be considered work in progress and does not represent its final state.
- Here, I would like to further state the inspiration behind the project came from Data with Baraa.
- Some parts of this code were written with help from ChatGPT as a development assistant. Mostly bug hunting.

# Repo Structure (High-Level)
    .
    ├── docs/                     # Diagrams and documentation assets
    ├── scripts/
          ├── bronze/             # Python scripts regarding Bronze Layer
          ├── silver/             # Stored procedures for Silver Layer
                ├── sp_inserts    # Individual stored procedures for inserting (loading) of Silver Layer
          ├── gold/               # Stored procedures for Gold Layer
          ├── validity/           # Stored procedures looking for duplicates, nulls, etc., for each layer
    └── README.md
