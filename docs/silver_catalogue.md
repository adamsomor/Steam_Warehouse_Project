# Silver Layer Data Catalogue
---

### Table: `dim_category`

| Column                  | PK  | FK  | Data Type | Description                             |
|-------------------------|-----|-----|-----------|-----------------------------------------|
| `category_id`           | PK  |     | INTEGER   | Unique identifier for category.         |
| `category_description`  |     |     | TEXT      | Description/name of the category.       |

---

### Table: `dim_genre`

| Column                 | PK  | FK  | Data Type | Description                           |
|------------------------|-----|-----|-----------|---------------------------------------|
| `genre_id`             | PK  |     | INTEGER   | Unique genre identifier.              |
| `genre_description`    |     |     | TEXT      | Description/name of the genre.        |

---

### Table: `dim_developer`

| Column                 | PK  | FK  | Data Type | Description                              |
|------------------------|-----|-----|-----------|------------------------------------------|
| `developer_id`         | PK  |     | SERIAL    | Unique developer identifier (autogen).   |
| `developer_name`       |     |     | TEXT      | Name of the developer.                   |

---

### Table: `dim_agency`

| Column                  | PK  | FK  | Data Type | Description                                  |
|-------------------------|-----|-----|-----------|----------------------------------------------|
| `rating_agency_id`      | PK  |     | SERIAL    | Unique rating‑agency identifier (autogen).   |
| `agency_code`           |     |     | TEXT      | Code/name of the rating agency.              |

---

### Table: `dim_publisher`

| Column                  | PK  | FK  | Data Type | Description                                  |
|-------------------------|-----|-----|-----------|----------------------------------------------|
| `publisher_id`          | PK  |     | SERIAL    | Unique publisher identifier (autogen).       |
| `publisher_name`        |     |     | TEXT      | Name of the publisher.                       |

---

### Table: `hub_author`

| Column                  | PK  | FK  | Data Type   | Description                                 |
|-------------------------|-----|-----|-------------|---------------------------------------------|
| `steamid`               | PK  |     | BIGINT      | Unique Steam ID of review author.           |
| `num_reviews`           |     |     | INTEGER     | Number of reviews written by author.        |
| `num_games_owned`       |     |     | INTEGER     | Number of games owned by author.            |
| `playtime_forever`      |     |     | INTEGER     | Total playtime in minutes.                  |
| `playtime_at_review`    |     |     | INTEGER     | Playtime at time of review.                 |
| `playtime_last_two_weeks`|    |     | INTEGER     | Playtime in last two weeks.                 |
| `last_played`           |     |     | TIMESTAMPTZ | Timestamp of last played date.              |

---

### Table: `hub_game`

| Column                  | PK  | FK  | Data Type   | Description                                         |
|-------------------------|-----|-----|-------------|-----------------------------------------------------|
| `steam_appid`           | PK  |     | INTEGER     | Steam app ID (game identifier).                     |
| `name`                  |     |     | TEXT        | Name of the game.                                   |
| `required_age`          |     |     | INTEGER     | Required minimum age to play.                       |
| `is_free`               |     |     | BOOLEAN     | Is the game free to play.                           |
| `alternate_appid`       |     |     | INTEGER     | Alternate Steam app ID if exists.                   |
| `controller_support`    |     |     | TEXT        | Controller support status (`Y`, `N`, `N/A`).        |
| `type`                  |     |     | TEXT        | Type of the app (`game`, `dlc`).                    |
| `price_currency`        |     |     | TEXT        | Currency of the price (e.g. USD).                   |
| `price_initial`         |     |     | INTEGER     | Initial price in cents/pennies.                     |
| `price_final`           |     |     | INTEGER     | Final discounted price in cents.                    |
| `price_discount_percent`|     |     | INTEGER     | Percent discount applied.                           |
| `metacritic_score`      |     |     | INTEGER     | Metacritic score (if available).                    |
| `recommendation_count`  |     |     | INTEGER     | Total number of user recommendations.               |
| `release_date`          |     |     | DATE        | Official release date of the game.                  |
| `coming_soon`           |     |     | BOOLEAN     | Flag if the game is 'coming soon'.                  |
| `achievements_total`    |     |     | INTEGER     | Total achievements count in the game.               |

---

### Table: `bridge_publisher`

| Column         | PK  | FK                         | Data Type | Description                       |
|----------------|-----|----------------------------|-----------|-----------------------------------|
| `steam_appid`  | PK  | FK → `hub_game`            | INTEGER   | Steam app ID for the game.        |
| `publisher_id` | PK  | FK → `dim_publisher`       | INTEGER   | Publisher ID of the game.         |

---

### Table: `bridge_category`

| Column         | PK  | FK                           | Data Type | Description                          |
|----------------|-----|------------------------------|-----------|--------------------------------------|
| `steam_appid`  | PK  | FK → `hub_game`              | INTEGER   | Steam app ID referring to a game.    |
| `category_id`  | PK  | FK → `dim_category`          | INTEGER   | Category ID associated with the game.|

---

### Table: `bridge_genre`

| Column         | PK  | FK                        | Data Type | Description                       |
|----------------|-----|---------------------------|-----------|-----------------------------------|
| `steam_appid`  | PK  | FK → `hub_game`           | INTEGER   | Steam app ID of the game.         |
| `genre_id`     | PK  | FK → `dim_genre`          | INTEGER   | Genre ID associated with the game.|

---

### Table: `bridge_developer`

| Column         | PK  | FK                              | Data Type | Description                           |
|----------------|-----|---------------------------------|-----------|---------------------------------------|
| `steam_appid`  | PK  | FK → `hub_game`                 | INTEGER   | Steam app game ID.                    |
| `developer_id` | PK  | FK → `dim_developer`            | INTEGER   | Developer ID associated with game.    |

---

### Table: `bridge_platform`

| Column         | PK  | FK                      | Data Type | Description                         |
|----------------|-----|-------------------------|-----------|-------------------------------------|
| `steam_appid`  | PK  | FK → `hub_game`         | INTEGER   | Steam app ID for a game.            |
| `platform`     | PK  |                         | TEXT      | Platform name (`windows`, `linux`). |

---

### Table: `fct_rating`

| Column             | PK  | FK                             | Data Type | Description                                  |
|--------------------|-----|--------------------------------|-----------|----------------------------------------------|
| `steam_appid`      | PK  | FK → `hub_game`                | INTEGER   | Game's Steam app ID.                         |
| `rating_agency_id` | PK  | FK → `dim_agency`              | INTEGER   | Rating agency ID.                            |
| `rating`           |     |                                | TEXT      | Rating given by the agency.                  |
| `required_age`     |     |                                | INTEGER   | Minimum age required as per rating.          |
| `banned`           |     |                                | BOOLEAN   | Game banned flag according to rating.        |
| `use_age_gate`     |     |                                | BOOLEAN   | Whether age gate was used.                   |
| `rating_generated` |     |                                | BOOLEAN   | Whether rating was auto‑generated.           |

---

### Table: `fct_review_stat`

| Column                    | PK  | FK                          | Data Type    | Description                              |
|---------------------------|-----|-----------------------------|--------------|------------------------------------------|
| `recommendation_id`       | PK  |                             | BIGINT       | Unique identifier for the review record. |
| `steam_appid`             |     | FK → `hub_game`             | INTEGER      | Steam app ID of reviewed game.           |
| `language`                |     |                             | TEXT         | Language of the review.                  |
| `timestamp_created`       |     |                             | TIMESTAMPTZ  | When the review was created.             |
| `timestamp_updated`       |     |                             | TIMESTAMPTZ  | When the review was last updated.        |
| `author_steamid`          |     | FK → `hub_author`           | BIGINT       | Steam ID of the review author.           |
| `voted_up`                |     |                             | BOOLEAN      | True if review was voted up.             |
| `votes_up`                |     |                             | BIGINT       | Number of up‑votes.                      |
| `votes_funny`             |     |                             | BIGINT       | Number of “funny” votes (nullable).      |
| `comment_count`           |     |                             | BIGINT       | Number of comments on the review.        |
| `steam_purchase`          |     |                             | BOOLEAN      | Review from a Steam purchase.            |
| `received_for_free`       |     |                             | BOOLEAN      | Review posted for a free copy.           |
| `weighted_vote_score`     |     |                             | REAL         | Weighted score of votes (nullable).      |
| `primarily_steam_deck`    |     |                             | BOOLEAN      | Flag if written on Steam Deck.           |
| `written_during_early_access` | |                             | BOOLEAN      | Flag if written during early access.     |

---

### Table: `sat_review_text`

| Column               | PK  | FK                            | Data Type | Description                            |
|----------------------|-----|-------------------------------|-----------|----------------------------------------|
| `review_stat_rec_id` | PK  | FK → `fct_review_stat`        | BIGINT    | Reference to the review‑stat record.   |
| `review_text`        |     |                               | TEXT      | Full text content of the game review.  |

---
