-- ===================================
-- DIMENSIONS
-- ===================================

-- DUPLICATES
SELECT
	COUNT(*) - COUNT(DISTINCT publisher_name)
FROM silver.dim_publishers;

-- DUPLICATES
SELECT
	COUNT(*) - COUNT(DISTINCT developer_name)
FROM silver.dim_developers;

-- NULLS
SELECT
	COUNT(*) FILTER (WHERE publisher_name IS NULL)
FROM silver.dim_publishers;

-- NULLS
SELECT
	COUNT(*) FILTER (WHERE developer_name IS NULL)
FROM silver.dim_developers;

-- UNIQUE ID AND DESCRIPTION CHECK
SELECT
	COUNT(*) FILTER (WHERE category_description IS NULL)
FROM silver.dim_categories;

-- UNIQUE ID AND DESCRIPTION CHECK
SELECT
	COUNT(*) - COUNT(DISTINCT category_description)
FROM silver.dim_categories;
									-- count of unique id is 1

-- UNIQUE ID AND DESCRIPTION CHECK
SELECT
	COUNT(*) FILTER (WHERE genre_description IS NULL)
FROM silver.dim_genres;

-- UNIQUE ID AND DESCRIPTION CHECK
SELECT
	COUNT(*) - COUNT(DISTINCT genre_description)
FROM silver.dim_genres;

-- CHECK FOR VALID NON-EMPTY AGENCY_CODE
SELECT
	COUNT(*) FILTER (WHERE agency_code IS NULL OR agency_code = '')
FROM silver.dim_rating_agencies;

-- UNIQUE ID AND DESCRIPTION CHECK
SELECT
	COUNT(*) - COUNT(DISTINCT agency_code)
FROM silver.dim_rating_agencies;

-- ===================================
-- BRIDGE TABLES 
-- ===================================

-- ORPHAN CHECK FOR BRIDGE TABLE
SELECT
	COUNT(*)
FROM silver.game_publishers gp
LEFT JOIN silver.games_master gm ON gp.steam_appid = gm.steam_appid
WHERE gm.steam_appid IS NULL;

-- DUPLICATE COMPOSITE KEYS
SELECT
	steam_appid,
	publisher_id,
	COUNT(*)
FROM silver.game_publishers
GROUP BY steam_appid, publisher_id
HAVING COUNT(*) > 1;

-- SUSPICIOUS RATINGS, AGES, OR LOGICAL ERRORS
SELECT
	COUNT(*) FILTER (WHERE rating IS NULL OR rating = '') AS missing_rating,
    COUNT(*) FILTER (WHERE required_age < 0) AS negative_age,
    COUNT(*) FILTER (WHERE use_age_gate IS NULL) AS null_gate_flag
FROM silver.game_ratings;
									-- missing rating 4105 and null gate flag 18926

-- ===================================
-- TABLE: game_platforms
-- ===================================

-- NULLS AND ORPHAN STEAM_APPIDS
SELECT
	COUNT(*) FILTER (WHERE steam_appid IS NULL OR platform IS NULL)
FROM silver.game_platforms;

-- FOREIGN KEY ORPHAN
SELECT
	COUNT(*)
FROM silver.game_platforms gp
LEFT JOIN silver.games_master gm ON gp.steam_appid = gm.steam_appid
WHERE gm.steam_appid IS NULL;

-- DISTINCT PLATFORM VALUES SANITY CHECK
SELECT
	DISTINCT platform
FROM silver.game_platforms;

-- ===================================
-- TABLE: review_authors
-- ===================================

-- CHECK FOR DUPLICATE AUTHOR STEAMIDS
SELECT
	COUNT(*) - COUNT(DISTINCT steamid) AS duplicates
FROM silver.review_authors;

-- CHECK FOR SUSPICIOUS NULLS
SELECT
	COUNT(*) FILTER (WHERE steamid IS NULL) AS nulls,
    COUNT(*) FILTER (WHERE num_games_owned < 0 OR num_reviews < 0) AS negatives
FROM silver.review_authors;

-- ===================================
-- TABLE: game_review_stats
-- ===================================

-- CHECK FOR NULLS IN FOREIGN KEY REFERENCES
SELECT
	COUNT(*) FILTER (WHERE steam_appid IS NULL OR author_steamid IS NULL) AS null_foreign_keys
FROM silver.game_review_stats;

-- CHECK FOR OUT-OF-RANGE VOTE COUNTS
SELECT
	COUNT(*) FILTER (WHERE votes_up < 0 OR votes_funny < 0 OR comment_count < 0) AS bad_votes
FROM silver.game_review_stats;

-- ===================================
-- TABLE: game_reviews
-- ===================================

-- CHECK FOR ORPHAN FOREIGN KEYS (SHOULD BE 0)
SELECT
	COUNT(*)
FROM silver.game_reviews r
LEFT JOIN silver.game_review_stats s ON r.review_stat_rec_id = s.id
WHERE s.id IS NULL;

-- NULL OR EMPTY REVIEW_TEXT
SELECT
	COUNT(*) FILTER (WHERE review_text IS NULL OR review_text = '') AS bad_reviews
FROM silver.game_reviews;
									-- count of bad reviews is 66536
									
-- ===================================
-- TABLE: games_master
-- ===================================

-- CHECK STEAM_APPID DUPLICATES AND NULLS
SELECT 
  COUNT(*) FILTER (WHERE steam_appid IS NULL) AS nulls,
  COUNT(*) - COUNT(DISTINCT steam_appid) AS duplicates
FROM silver.games_master;

-- CHECKS IF NAME IS EMPTY, N/A, OR NEITHER
SELECT 
  COUNT(*) FILTER (WHERE name IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE name = '') AS empty,
  COUNT(*) FILTER (WHERE name = 'N/A') AS default_na,
  COUNT (*) FILTER(WHERE name != '' and name != 'N/A') AS names
FROM silver.games_master;

-- CHECKS IF REQUIRED_AGE IS NULL, LESS THAN 0, ABOVE 100, BETWEEN 0 AND 100
SELECT 
  COUNT(*) FILTER (WHERE required_age IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE required_age < 0) AS negative,
  COUNT(*) FILTER (WHERE required_age > 100) AS suspicious_high,
  COUNT(*) FILTER (WHERE required_age BETWEEN 0 AND 100) AS ages
FROM silver.games_master;

-- CHECKS IF IS_FREE IS NULL; DISTINCT VALUES, IT SHOWS THE DISTINCT VALUES
SELECT 
  COUNT(*) FILTER (WHERE is_free IS NULL) AS nulls,
  COUNT(DISTINCT is_free) AS distinct_values,
  ARRAY_AGG(DISTINCT is_free) AS values
FROM silver.games_master;

-- CHECKS IF ALTERNATE_APPID IS NULL, BELLOW 0, EQUAL TO 0, OR BETWEEN 0 AND 999999
SELECT 
  COUNT(*) FILTER (WHERE alternate_appid IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE alternate_appid < 0) AS negative,
  COUNT(*) FILTER (WHERE alternate_appid = 0) AS default_zero,
  COUNT(*) FILTER (WHERE alternate_appid BETWEEN 0 AND 999999) AS up_to_999999
FROM silver.games_master;

-- CHECKS IF CONTROLLER_SUPPORT IS NULL, EMPTY, N/A, AND DISPLAYS DISTINCT VALUES
SELECT 
  COUNT(*) FILTER (WHERE controller_support IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE controller_support = '') AS empty,
  COUNT(*) FILTER (WHERE controller_support = 'N/A') AS default_na,
  ARRAY_AGG(DISTINCT controller_support) AS distinct_values
FROM silver.games_master;

-- Checks if type is null, empty, N/A, and displays distinct values 
SELECT 
  COUNT(*) FILTER (WHERE type IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE type = '') AS empty,
  COUNT(*) FILTER (WHERE type = 'N/A') AS default_na,
  ARRAY_AGG(DISTINCT type) AS distinct_types
FROM silver.games_master;

-- CHECKS IF PRICE_CURRENCY IS NULL, EMPTY, N/A, AND DISPLAYS DISTINCT VALUES 
SELECT 
  COUNT(*) FILTER (WHERE price_currency IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE price_currency = '') AS empty,
  COUNT(*) FILTER (WHERE price_currency = 'N/A') AS default_na,
  ARRAY_AGG(DISTINCT price_currency) AS currencies
FROM silver.games_master;

-- CHECKS IF PRICE_INITIAL / PRICE_FINAL / PRICE_DISCOUNT_PERCENT ARE NULLS, EMPTY, N/A, OR WHETHER INITIAL PRICE IS LESS THAN FINAL PRICE 
SELECT 
  COUNT(*) FILTER (WHERE price_initial IS NULL) AS initial_nulls,
  COUNT(*) FILTER (WHERE price_final IS NULL) AS final_nulls,
  COUNT(*) FILTER (WHERE price_discount_percent IS NULL) AS discount_nulls,
  COUNT(*) FILTER (WHERE price_initial < price_final) AS bad_price_logic
FROM silver.games_master;

-- CHECKS IF METACRITIC_SCORE IS NULL OR OUT OF RANGE (BELLOW 0, ABOVE 100)
SELECT 
  COUNT(*) FILTER (WHERE metacritic_score IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE metacritic_score < 0 OR metacritic_score > 100) AS out_of_range
FROM silver.games_master;

-- CHECKS IF RECOMMENDATION_COUNT IS NULL OR BELLOW 0
SELECT 
  COUNT(*) FILTER (WHERE recommendation_count IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE recommendation_count < 0) AS negative
FROM silver.games_master;

-- CHECKS IF RELEASE_DATE IS NULL, IS DEFAULT DATE (YYYY-MM-DD), CHECKS MIN AND MAX DATE.
SELECT 
  COUNT(*) FILTER (WHERE release_date IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE release_date = '1970-01-01') AS default_epoch,
  MIN(release_date), MAX(release_date)
FROM silver.games_master;

-- CHECKS IF COMMING_SOON IS NULL AND DISPLAYS DISTINCT VALUES 
SELECT 
  COUNT(*) FILTER (WHERE coming_soon IS NULL) AS nulls,
  ARRAY_AGG(DISTINCT coming_soon) AS values
FROM silver.games_master;

-- CHECKS IF ACHIEVEMENTS_TOTAL IS NULL OR BELLOW 0
SELECT 
  COUNT(*) FILTER (WHERE achievements_total IS NULL) AS nulls,
  COUNT(*) FILTER (WHERE achievements_total < 0) AS negative
FROM silver.games_master;

-- ===================================
-- HIGH-LEVEL CROSS-TABLE CONSISTENCY
-- ===================================

-- GAMES THAT APPEAR IN MASTER BUT NOWHERE ELSE
SELECT
	steam_appid
FROM silver.games_master
EXCEPT
SELECT
	DISTINCT
	steam_appid FROM (
		  SELECT
		  	steam_appid
		  FROM silver.game_publishers
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_genres
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_developers
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_categories
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_platforms
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_ratings
		  			UNION ALL
		  SELECT
		  	steam_appid
		  FROM silver.game_review_stats
		) x;