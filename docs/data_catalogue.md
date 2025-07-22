# Data Catalog — Silver Layer (Normalized Schema)

This catalog documents the normalized structure of the Steam dataset used in the `silver` schema.  
The schema adheres to standard data warehouse modeling practices (dimension-fact-bridge separation, enforced referential integrity).

---

## Core Table

### `games_master`
Stores primary game metadata.

| Column                | Type      | Description |
|-----------------------|-----------|-------------|
| steam_appid           | INTEGER   | Unique game ID from Steam (PK) |
| name                  | TEXT      | Game title |
| required_age          | INTEGER   | Minimum age restriction |
| is_free               | BOOLEAN   | Whether the game is free |
| alternate_appid       | INTEGER   | Alternate app ID if applicable |
| controller_support    | TEXT      | Controller compatibility |
| type                  | TEXT      | App type (e.g., game, DLC) |
| price_currency        | TEXT      | Currency code (e.g., USD, EUR) |
| price_initial         | INTEGER   | Original price |
| price_final           | INTEGER   | Discounted price |
| price_discount_percent| INTEGER   | Discount percentage |
| metacritic_score      | INTEGER   | Metacritic score (0–100) |
| recommendation_count  | INTEGER   | Steam recommendation count |
| release_date          | DATE      | Release date |
| coming_soon           | BOOLEAN   | If marked as upcoming |
| achievements_total    | INTEGER   | Total number of achievements |

---

## Dimension Tables

### `dim_publishers`
Unique publisher names.

| Column         | Type    | Description |
|----------------|---------|-------------|
| publisher_id   | SERIAL  | Surrogate key (PK) |
| publisher_name | TEXT    | Publisher name (unique) |

---

### `dim_developers`
Unique developer names.

| Column         | Type    | Description |
|----------------|---------|-------------|
| developer_id   | SERIAL  | Surrogate key (PK) |
| developer_name | TEXT    | Developer name (unique) |

---

### `dim_genres`
Genre lookup.

| Column            | Type    | Description |
|-------------------|---------|-------------|
| genre_id          | INTEGER | Genre ID (PK) |
| genre_description | TEXT    | Human-readable genre label |

---

### `dim_categories`
Category lookup.

| Column               | Type    | Description |
|----------------------|---------|-------------|
| category_id          | INTEGER | Category ID (PK) |
| category_description | TEXT    | Description of category |

---

### `dim_rating_agencies`
Video game rating agencies.

| Column         | Type   | Description |
|----------------|--------|-------------|
| rating_agency_id | SERIAL | Surrogate key (PK) |
| agency_code      | TEXT   | Agency identifier (e.g., 'esrb') |

---

## 🔗 Bridge Tables (Many-to-Many Relationships)

### `game_publishers`
Links games to one or more publishers.

| Column         | Type    | Description |
|----------------|---------|-------------|
| steam_appid    | INTEGER | FK → games_master |
| publisher_id   | INTEGER | FK → dim_publishers |

---

### `game_developers`
Links games to developers.

| Column         | Type    | Description |
|----------------|---------|-------------|
| steam_appid    | INTEGER | FK → games_master |
| developer_id   | INTEGER | FK → dim_developers |

---

### `game_genres`
Links games to genres.

| Column      | Type    | Description |
|-------------|---------|-------------|
| steam_appid | INTEGER | FK → games_master |
| genre_id    | INTEGER | FK → dim_genres |

---

### `game_categories`
Links games to categories.

| Column      | Type    | Description |
|-------------|---------|-------------|
| steam_appid | INTEGER | FK → games_master |
| category_id | INTEGER | FK → dim_categories |

---

### `game_ratings`
Game ratings from different agencies.

| Column                 | Type     | Description |
|------------------------|----------|-------------|
| steam_appid            | INTEGER  | FK → games_master |
| rating_agency_id       | INTEGER  | FK → dim_rating_agencies |
| rating                 | TEXT     | Rating value (e.g., 'M', '12') |
| required_age           | INTEGER  | Implied age gate |
| banned                 | BOOLEAN  | Whether banned in region |
| use_age_gate           | BOOLEAN  | If age gate is enforced |
| rating_generated       | BOOLEAN  | Whether inferred or official |

---

## Other Fact-Like Tables

### `game_platforms`
Platform availability.

| Column      | Type    | Description |
|-------------|---------|-------------|
| steam_appid | INTEGER | FK → games_master |
| platform    | TEXT    | Platform name (e.g., 'windows', 'mac', 'linux') |

---

### `review_authors`
Metadata for reviewers.

| Column                  | Type     | Description |
|-------------------------|----------|-------------|
| steamid                 | BIGINT   | Unique user ID (PK) |
| num_reviews             | INTEGER  | Number of reviews submitted |
| num_games_owned         | INTEGER  | Game library size |
| playtime_forever        | INTEGER  | Total playtime |
| playtime_at_review      | INTEGER  | Playtime before submitting review |
| playtime_last_two_weeks | INTEGER  | Recent activity (2 weeks) |
| last_played             | TIMESTAMP| Most recent play session |

---

### `game_review_stats`
Structured metadata of reviews (not full text).

| Column                    | Type     | Description |
|---------------------------|----------|-------------|
| id                        | BIGINT   | PK (sequence) |
| recommendation_id         | BIGINT   | Steam review ID |
| steam_appid               | INTEGER  | FK → games_master |
| author_steamid            | BIGINT   | FK → review_authors |
| language                  | TEXT     | Language of review |
| timestamp_created         | TIMESTAMP| When review was posted |
| timestamp_updated         | TIMESTAMP| Last update to review |
| voted_up                  | BOOLEAN  | Positive or negative |
| votes_up                  | BIGINT   | Helpful votes |
| votes_funny               | BIGINT   | Funny votes |
| comment_count             | BIGINT   | Replies to review |
| steam_purchase            | BOOLEAN  | Bought on Steam |
| received_for_free         | BOOLEAN  | Free copy |
| weighted_vote_score       | REAL     | Steam's ranking weight |
| primarily_steam_deck      | BOOLEAN  | Indicates Deck usage |
| written_during_early_access | BOOLEAN | Review from early access phase |

---

### `game_reviews`
Review text (raw body).

| Column               | Type   | Description |
|----------------------|--------|-------------|
| id                   | BIGINT | PK (sequence) |
| review_stat_rec_id   | BIGINT | FK → game_review_stats(id) |
| review_text          | TEXT   | Raw user review |
