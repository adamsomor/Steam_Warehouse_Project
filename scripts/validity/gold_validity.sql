-- =======================================
-- 1) DIMENSION TABLES
-- =======================================

-- dim_games
-- PK nulls & duplicates
SELECT
  COUNT(*) FILTER (WHERE game_id IS NULL)          AS null_ids,
  COUNT(*) - COUNT(DISTINCT game_id)               AS duplicate_ids
FROM gold.dim_games;

-- price logic: final < initial?
SELECT
  COUNT(*) FILTER (WHERE price_final > price_initial) AS bad_price_logic
FROM gold.dim_games;


-- dim_platforms
SELECT
  COUNT(*) FILTER (WHERE platform_id IS NULL)         AS null_ids,
  COUNT(*) - COUNT(DISTINCT platform_id)              AS duplicate_ids,
  COUNT(*) FILTER (WHERE platform IS NULL OR platform='') AS null_platforms
FROM gold.dim_platforms;


-- dim_genres
SELECT
  COUNT(*) FILTER (WHERE genre_id IS NULL)              AS null_ids,
  COUNT(*) FILTER (WHERE genre_description IS NULL)     AS null_desc,
  COUNT(*) - COUNT(DISTINCT genre_id)                   AS duplicate_ids,
  COUNT(*) - COUNT(DISTINCT genre_description)          AS duplicate_desc
FROM gold.dim_genres;


-- dim_categories
SELECT
  COUNT(*) FILTER (WHERE category_id IS NULL)           AS null_ids,
  COUNT(*) FILTER (WHERE category_description IS NULL)  AS null_desc,
  COUNT(*) - COUNT(DISTINCT category_id)                AS duplicate_ids,
  COUNT(*) - COUNT(DISTINCT category_description)       AS duplicate_desc
FROM gold.dim_categories;


-- dim_publishers
SELECT
  COUNT(*) FILTER (WHERE publisher_id IS NULL)          AS null_ids,
  COUNT(*) FILTER (WHERE publisher_name IS NULL)        AS null_names,
  COUNT(*) - COUNT(DISTINCT publisher_id)               AS duplicate_ids,
  COUNT(*) - COUNT(DISTINCT publisher_name)             AS duplicate_names
FROM gold.dim_publishers;


-- dim_developers
SELECT
  COUNT(*) FILTER (WHERE developer_id IS NULL)          AS null_ids,
  COUNT(*) FILTER (WHERE developer_name IS NULL)        AS null_names,
  COUNT(*) - COUNT(DISTINCT developer_id)               AS duplicate_ids,
  COUNT(*) - COUNT(DISTINCT developer_name)             AS duplicate_names
FROM gold.dim_developers;


-- dim_rating_agencies
SELECT
  COUNT(*) FILTER (WHERE rating_agency_id IS NULL)      AS null_ids,
  COUNT(*) FILTER (WHERE agency_code IS NULL OR agency_code='') AS bad_codes,
  COUNT(*) - COUNT(DISTINCT rating_agency_id)           AS duplicate_ids,
  COUNT(*) - COUNT(DISTINCT agency_code)                AS duplicate_codes
FROM gold.dim_rating_agencies;


-- dim_review_authors
SELECT
  COUNT(*) FILTER (WHERE author_id IS NULL)             AS null_ids,
  COUNT(*) - COUNT(DISTINCT author_id)                  AS duplicate_ids,
  COUNT(*) FILTER (WHERE num_reviews < 0 OR num_games_owned < 0) AS negative_counts
FROM gold.dim_review_authors;


-- =======================================
-- 2) FACT TABLES
-- =======================================

-- fact_game_platforms
SELECT
  COUNT(*)                                            	AS total_rows,
  COUNT(*) - COUNT(DISTINCT (game_id, platform_id)) 	AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR platform_id IS NULL) AS null_keys
FROM gold.fact_game_platforms;

-- orphan FK check:
SELECT COUNT(*) 
FROM gold.fact_game_platforms f
LEFT JOIN gold.dim_games       g ON f.game_id     = g.game_id
LEFT JOIN gold.dim_platforms  p ON f.platform_id = p.platform_id
WHERE g.game_id IS NULL OR p.platform_id IS NULL;


-- fact_game_genres
SELECT
  COUNT(*)                                            AS total_rows,
  COUNT(*) - COUNT(DISTINCT (game_id, genre_id))      AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR genre_id IS NULL) AS null_keys
FROM gold.fact_game_genres;
SELECT COUNT(*)
FROM gold.fact_game_genres f
LEFT JOIN gold.dim_games g ON f.game_id = g.game_id
LEFT JOIN gold.dim_genres d ON f.genre_id = d.genre_id
WHERE g.game_id IS NULL OR d.genre_id IS NULL;


-- fact_game_categories
SELECT
  COUNT(*)                                            AS total_rows,
  COUNT(*) - COUNT((DISTINCT game_id, category_id))   AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR category_id IS NULL) AS null_keys
FROM gold.fact_game_categories;
SELECT COUNT(*)
FROM gold.fact_game_categories f
LEFT JOIN gold.dim_games      g ON f.game_id      = g.game_id
LEFT JOIN gold.dim_categories c ON f.category_id  = c.category_id
WHERE g.game_id IS NULL OR c.category_id IS NULL;


-- fact_game_publishers
SELECT
  COUNT(*)                                            AS total_rows,
  COUNT(*) - COUNT(DISTINCT (game_id, publisher_id))    AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR publisher_id IS NULL) AS null_keys
FROM gold.fact_game_publishers;
SELECT COUNT(*)
FROM gold.fact_game_publishers f
LEFT JOIN gold.dim_games      g ON f.game_id       = g.game_id
LEFT JOIN gold.dim_publishers p ON f.publisher_id = p.publisher_id
WHERE g.game_id IS NULL OR p.publisher_id IS NULL;


-- fact_game_developers
SELECT
  COUNT(*)                                            AS total_rows,
  COUNT(*) - COUNT(DISTINCT (game_id, developer_id))    AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR developer_id IS NULL) AS null_keys
FROM gold.fact_game_developers;
SELECT COUNT(*)
FROM gold.fact_game_developers f
LEFT JOIN gold.dim_games      g ON f.game_id       = g.game_id
LEFT JOIN gold.dim_developers d ON f.developer_id  = d.developer_id
WHERE g.game_id IS NULL OR d.developer_id IS NULL;


-- fact_game_ratings
SELECT
  COUNT(*)													AS total_rows,
  COUNT(*) - COUNT(DISTINCT (game_id, rating_agency_id))	AS duplicate_keys,
  COUNT(*) FILTER (WHERE game_id IS NULL OR rating_agency_id IS NULL) AS null_keys
FROM gold.fact_game_ratings;
SELECT COUNT(*)
FROM gold.fact_game_ratings f
LEFT JOIN gold.dim_games            g ON f.game_id           = g.game_id
LEFT JOIN gold.dim_rating_agencies a ON f.rating_agency_id  = a.rating_agency_id
WHERE g.game_id IS NULL OR a.rating_agency_id IS NULL;


-- fact_reviews_agg
SELECT
  COUNT(*)                                    AS total_games,
  COUNT(*) FILTER (WHERE review_count = 0)    AS no_reviews,
  COUNT(*) FILTER (WHERE avg_weighted_vote_score < 0 OR avg_weighted_vote_score > 1) AS bad_scores,
  COUNT(*) FILTER (WHERE total_votes_up < 0 OR total_votes_funny < 0)             AS bad_votes
FROM gold.fact_reviews_agg;
SELECT COUNT(*)
FROM gold.fact_reviews_agg a
LEFT JOIN gold.dim_games g ON a.game_id = g.game_id
WHERE g.game_id IS NULL;


-- fact_reviews
SELECT
  COUNT(*)                                              AS total_reviews,
  COUNT(*) FILTER (WHERE id IS NULL)                     AS null_ids,
  COUNT(*) FILTER (WHERE recommendation_id IS NULL)      AS null_recid,
  COUNT(*) FILTER (WHERE steam_purchase IS NULL)         AS null_purchase_flag
FROM gold.fact_reviews;
SELECT COUNT(*) - COUNT(DISTINCT id) AS duplicate_ids
FROM gold.fact_reviews;
-- orphan FK to fact_reviews_agg
SELECT COUNT(*)
FROM gold.fact_reviews r
LEFT JOIN gold.fact_reviews_agg a ON r.review_stat_id = a.review_stat_id
WHERE a.review_stat_id IS NULL;
-- orphan FK to dim_review_authors
SELECT COUNT(*)
FROM gold.fact_reviews r
LEFT JOIN gold.dim_review_authors d ON r.author_id = d.author_id
WHERE d.author_id IS NULL;
