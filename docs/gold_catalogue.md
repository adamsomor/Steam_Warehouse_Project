# Gold Layer Data Catalogue

---

### Table: `dim_games`

| Column              | PK  | FK  | Data Type | Description                                                     |
|---------------------|-----|-----|-----------|-----------------------------------------------------------------|
| `game_id`           | PK  |     | INTEGER   | Unique game identifier (Steam app ID).                         |
| `name`              |     |     | TEXT      | Name of the game.                                               |
| `required_age`      |     |     | INTEGER   | Minimum required age to play the game.                         |
| `is_free`           |     |     | BOOLEAN   | Whether the game is free to play.                              |
| `alternate_appid`   |     |     | INTEGER   | Alternate Steam app ID, if any (0 if none).                    |
| `controller_support` |     |     | TEXT      | Controller support info ('Y', 'N', 'N/A', etc.).               |
| `type`              |     |     | TEXT      | Type of the app (e.g., "game", "dlc").                         |
| `price_currency`    |     |     | TEXT      | Currency code of the price (e.g., USD).                        |
| `price_initial`     |     |     | NUMERIC(12,2) | Initial price (converted to standard unit like dollars).      |
| `price_final`       |     |     | NUMERIC(12,2) | Final discounted price.                                        |
| `price_discount_percent`|  |     | INTEGER   | Discount percent applied on the price.                         |
| `metacritic_score`  |     |     | INTEGER   | Metacritic game score (if available).                          |
| `recommendation_count` |  |     | INTEGER   | Total number of user recommendations.                         |
| `release_date`      |     |     | DATE      | Official release date of the game.                             |
| `coming_soon`       |     |     | BOOLEAN   | Flag indicating if the game is coming soon.                   |
| `achievements_total`|     |     | INTEGER   | Total number of achievements available in the game.           |

---

### Table: `dim_platforms`

| Column       | PK  | FK  | Data Type | Description                              |
|--------------|-----|-----|-----------|----------------------------------------|
| `platform_id`| PK  |     | INTEGER   | Unique platform identifier (generated).|
| `platform`   |     |     | TEXT      | Platform name (e.g., "windows", "linux", "mac").|

---

### Table: `dim_genre`

| Column             | PK  | FK  | Data Type | Description                     |
|--------------------|-----|-----|-----------|---------------------------------|
| `genre_id`         | PK  |     | INTEGER   | Unique genre identifier.        |
| `genre_description`|     |     | TEXT      | Description/name of the genre.  |

---

### Table: `dim_category`

| Column              | PK  | FK  | Data Type | Description                     |
|---------------------|-----|-----|-----------|---------------------------------|
| `category_id`       | PK  |     | INTEGER   | Unique category identifier.     |
| `category_description`|    |     | TEXT      | Description/name of the category.|

---

### Table: `dim_publisher`

| Column           | PK  | FK  | Data Type | Description                     |
|------------------|-----|-----|-----------|---------------------------------|
| `publisher_id`   | PK  |     | INTEGER   | Unique publisher identifier.    |
| `publisher_name` |     |     | TEXT      | Name of the publisher.          |

---

### Table: `dim_developer`

| Column           | PK  | FK  | Data Type | Description                     |
|------------------|-----|-----|-----------|---------------------------------|
| `developer_id`   | PK  |     | INTEGER   | Unique developer identifier.    |
| `developer_name` |     |     | TEXT      | Name of the developer.          |

---

### Table: `dim_agency`

| Column              | PK  | FK  | Data Type | Description                    |
|---------------------|-----|-----|-----------|-------------------------------|
| `rating_agency_id` | PK  |     | INTEGER   | Unique rating agency identifier.|
| `agency_code`      |     |     | TEXT      | Code or name of the rating agency.|

---

### Table: `dim_hub_author`

| Column               | PK  | FK  | Data Type   | Description                             |
|----------------------|-----|-----|-------------|-----------------------------------------|
| `author_id`          | PK  |     | BIGINT      | Unique Steam review author id (steamid).|
| `num_reviews`        |     |     | INTEGER     | Number of reviews written.              |
| `num_games_owned`    |     |     | INTEGER     | Number of games owned by the author.   |
| `playtime_forever`   |     |     | INTEGER     | Total playtime ever.                    |
| `playtime_at_review` |     |     | INTEGER     | Playtime at time of review.             |
| `playtime_last_two_weeks` | |   | INTEGER     | Playtime in the last two weeks.         |
| `last_played`        |     |     | TIMESTAMPTZ | Last time the user played any game.     |

---

### Fact Tables

#### Table: `fact_bridge_platform`

| Column       | PK           | FK                      | Data Type | Description                               |
|--------------|--------------|-------------------------|-----------|-------------------------------------------|
| `game_id`    | CPK          | FK to `dim_games(game_id)` | INTEGER   | Game identifier.                          |
| `platform_id`| CPK          | FK to `dim_platforms(platform_id)` | INTEGER   | Platform identifier.                      |

---

#### Table: `fact_bridge_genre`

| Column    | PK           | FK                     | Data Type | Description                           |
|-----------|--------------|------------------------|-----------|-------------------------------------|
| `game_id` | CPK          | FK to `dim_games(game_id)` | INTEGER   | Game identifier.                     |
| `genre_id`| CPK          | FK to `dim_genre(genre_id)` | INTEGER   | Genre identifier.                    |

---

#### Table: `fact_bridge_category`

| Column      | PK           | FK                     | Data Type | Description                           |
|-------------|--------------|------------------------|-----------|-------------------------------------|
| `game_id`   | CPK          | FK to `dim_games(game_id)` | INTEGER   | Game identifier.                     |
| `category_id`| CPK         | FK to `dim_category(category_id)` | INTEGER   | Category identifier.                 |

---

#### Table: `fact_bridge_publisher`

| Column      | PK           | FK                       | Data Type | Description                           |
|-------------|--------------|--------------------------|-----------|-------------------------------------|
| `game_id`   | CPK          | FK to `dim_games(game_id)`   | INTEGER   | Game identifier.                     |
| `publisher_id`| CPK         | FK to `dim_publisher(publisher_id)` | INTEGER   | Publisher identifier.                |

---

#### Table: `fact_bridge_developer`

| Column      | PK           | FK                         | Data Type | Description                           |
|-------------|--------------|----------------------------|-----------|-------------------------------------|
| `game_id`   | CPK          | FK to `dim_games(game_id)`   | INTEGER   | Game identifier.                     |
| `developer_id`| CPK         | FK to `dim_developer(developer_id)`| INTEGER   | Developer identifier.                |

---

#### Table: `fact_fct_rating`

| Column             | PK           | FK                           | Data Type | Description                                  |
|--------------------|--------------|------------------------------|-----------|----------------------------------------------|
| `game_id`          | CPK          | FK to `dim_games(game_id)`     | INTEGER   | Game identifier.                             |
| `rating_agency_id` | CPK          | FK to `dim_agency(rating_agency_id)` | INTEGER   | Rating agency identifier.                    |
| `rating`           |              |                              | TEXT      | Rating value from the agency (max if multiple).  |
| `required_age`     |              |                              | INTEGER   | Required minimum age (max if multiple).      |
| `banned`           |              |                              | BOOLEAN   | If game is banned (aggregated using BOOL_OR).|
| `use_age_gate`     |              |                              | BOOLEAN   | If age gate flag is used (BOOL_OR).          |
| `rating_generated` |              |                              | BOOLEAN   | If rating is auto-generated (BOOL_OR).       |

---

#### Table: `fact_reviews_agg`

| Column                | PK  | FK                     | Data Type    | Description                                              |
|-----------------------|-----|------------------------|--------------|----------------------------------------------------------|
| `game_id`             | PK  | FK to `dim_games(game_id)` | INTEGER    | Game identifier.                                         |
| `review_count`        |     |                        | INTEGER      | Total count of reviews for the game.                     |
| `avg_weighted_vote_score` |  |                       | NUMERIC(12,2)| Average weighted vote score of the reviews.              |
| `votes_up_sum`        |     |                        | INTEGER      | Number of positive votes summed across reviews.          |
| `total_votes_up`      |     |                        | INTEGER      | Total votes up count (sum).                               |
| `total_votes_funny`   |     |                        | INTEGER      | Total votes marked as funny.                              |
| `total_comments`      |     |                        | INTEGER      | Sum of comments on all reviews.                           |
| `latest_review`       |     |                        | TIMESTAMPTZ  | Timestamp of the most recent review.                      |
| `earliest_review`     |     |                        | TIMESTAMPTZ  | Timestamp of the oldest review.                           |
| `unique_reviewers`    |     |                        | INTEGER      | Number of unique reviewers for the game.                  |
| `avg_comment_count`   |     |                        | NUMERIC(12,2)| Average comments per review.                              |

---

#### Table: `fact_reviews`

| Column                   | PK  | FK                       | Data Type   | Description                                         |
|--------------------------|-----|--------------------------|-------------|-----------------------------------------------------|
| `review_stat_id`         | PK  |                          | BIGINT      | Unique review statistics record ID.                 |
| `recommendation_id`      |     |                          | BIGINT      | Steam recommendation ID related to review.         |
| `game_id`                |     | FK to `dim_games(game_id)` | INTEGER    | Game identifier.                                    |
| `author_id`              |     | FK to `dim_hub_author(author_id)` | BIGINT | Reviewer Steam ID.                                  |
| `language`               |     |                          | TEXT        | Language of the review.                             |
| `timestamp_created`      |     |                          | TIMESTAMPTZ | When the review was created.                         |
| `timestamp_updated`      |     |                          | TIMESTAMPTZ | When the review was last updated.                    |
| `voted_up`               |     |                          | BOOLEAN     | Whether the review was voted up.                     |
| `votes_up`               |     |                          | BIGINT      | Number of upvotes.                                  |
| `votes_funny`            |     |                          | BIGINT      | Number of funny votes.                              |
| `comment_count`          |     |                          | BIGINT      | Number of comments.                                 |
| `steam_purchase`         |     |                          | BOOLEAN     | Indicates if from Steam purchase.                    |
| `received_for_free`      |     |                          | BOOLEAN     | Review written for a free copy.                     |
| `weighted_vote_score`    |     |                          | REAL        | Weighted score of votes (nullable).                  |
| `primarily_steam_deck`   |     |                          | BOOLEAN     | Review written primarily on Steam Deck.             |
| `written_during_early_access` | |                        | BOOLEAN     | Review written during early access period.             |

---
