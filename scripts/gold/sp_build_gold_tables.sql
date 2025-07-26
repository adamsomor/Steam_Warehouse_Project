-- PROCEDURE: public.build_gold_tables()

-- DROP PROCEDURE IF EXISTS public.build_gold_tables();

CREATE OR REPLACE PROCEDURE public.build_gold_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	-- Drop and recreate gold schema if needed
	EXECUTE 'CREATE SCHEMA IF NOT EXISTS gold';
	
	------------------------------------------------------------
	-- 1) Dimensions (no aggregation needed)
	------------------------------------------------------------
	
	DROP TABLE IF EXISTS gold.dim_games CASCADE;
	CREATE TABLE gold.dim_games AS
	SELECT
	  steam_appid            AS game_id,
	  name,
	  required_age,
	  is_free,
	  alternate_appid,
	  controller_support,
	  type,
	  price_currency,
	  ROUND((price_initial::NUMERIC/100),2) AS price_initial,
	  ROUND((price_final  ::NUMERIC/100),2) AS price_final,
	  price_discount_percent,
	  metacritic_score,
	  recommendation_count,
	  release_date,
	  coming_soon,
	  achievements_total
	FROM silver.games_master;
	
	
	DROP TABLE IF EXISTS gold.dim_platforms CASCADE;
	CREATE TABLE gold.dim_platforms AS
	WITH uniq AS (
	  SELECT DISTINCT platform
	  FROM silver.game_platforms
	)
	SELECT
	  ROW_NUMBER() OVER (ORDER BY platform) AS platform_id,
	  platform
	FROM uniq;

	
	DROP TABLE IF EXISTS gold.dim_genres CASCADE;
	CREATE TABLE gold.dim_genres AS
	SELECT
	  genre_id,
	  genre_description
	FROM silver.dim_genres;
	
	
	DROP TABLE IF EXISTS gold.dim_categories CASCADE;
	CREATE TABLE gold.dim_categories AS
	SELECT
	  category_id,
	  category_description
	FROM silver.dim_categories;
	
	
	DROP TABLE IF EXISTS gold.dim_publishers CASCADE;
	CREATE TABLE gold.dim_publishers AS
	SELECT
	  publisher_id,
	  publisher_name
	FROM silver.dim_publishers;
	
	
	DROP TABLE IF EXISTS gold.dim_developers CASCADE;
	CREATE TABLE gold.dim_developers AS
	SELECT
	  developer_id,
	  developer_name
	FROM silver.dim_developers;
	
	
	DROP TABLE IF EXISTS gold.dim_rating_agencies CASCADE;
	CREATE TABLE gold.dim_rating_agencies AS
	SELECT
	  rating_agency_id,
	  agency_code
	FROM silver.dim_rating_agencies;
	
	
	DROP TABLE IF EXISTS gold.dim_review_authors CASCADE;
	CREATE TABLE gold.dim_review_authors AS
	SELECT
	  steamid       AS author_id,
	  num_reviews,
	  num_games_owned,
	  playtime_forever,
	  playtime_at_review,
	  playtime_last_two_weeks,
	  last_played
	FROM silver.review_authors;
	
	
	------------------------------------------------------------
	-- 2) Facts
	------------------------------------------------------------


	DROP TABLE IF EXISTS gold.fact_game_platforms CASCADE;
	CREATE TABLE gold.fact_game_platforms AS
	SELECT
	  gp.steam_appid AS game_id,
	  dp.platform_id
	FROM silver.game_platforms gp
	  JOIN gold.dim_platforms dp
	    ON gp.platform = dp.platform
	;

	
	DROP TABLE IF EXISTS gold.fact_game_genres CASCADE;
	CREATE TABLE gold.fact_game_genres AS
	SELECT
	  steam_appid AS game_id,
	  genre_id
	FROM silver.game_genres;
	
	
	DROP TABLE IF EXISTS gold.fact_game_categories CASCADE;
	CREATE TABLE gold.fact_game_categories AS
	SELECT
	  steam_appid  AS game_id,
	  category_id
	FROM silver.game_categories;
	
	
	DROP TABLE IF EXISTS gold.fact_game_publishers CASCADE;
	CREATE TABLE gold.fact_game_publishers AS
	SELECT
	  steam_appid   AS game_id,
	  publisher_id
	FROM silver.game_publishers;
	
	
	DROP TABLE IF EXISTS gold.fact_game_developers CASCADE;
	CREATE TABLE gold.fact_game_developers AS
	SELECT
	  steam_appid   AS game_id,
	  developer_id
	FROM silver.game_developers;
	
	
	-- Here we aggregate ratings per game and agency just in case multiple rows exist
	DROP TABLE IF EXISTS gold.fact_game_ratings CASCADE;
	CREATE TABLE gold.fact_game_ratings AS
	SELECT
	  steam_appid AS game_id,
	  rating_agency_id,
	  MAX(rating)            AS rating,
	  MAX(required_age)      AS required_age,
	  BOOL_OR(banned)        AS banned,
	  BOOL_OR(use_age_gate)  AS use_age_gate,
	  BOOL_OR(rating_generated) AS rating_generated
	FROM silver.game_ratings
	GROUP BY steam_appid, rating_agency_id;
	
	
	DROP TABLE IF EXISTS gold.fact_reviews_agg CASCADE;
	CREATE TABLE gold.fact_reviews_agg AS
	SELECT
	  steam_appid AS game_id,
	  COUNT(*) AS review_count,
	  ROUND(AVG(weighted_vote_score::NUMERIC),2) AS avg_weighted_vote_score,
	  SUM(CASE WHEN voted_up THEN 1 ELSE 0 END) AS votes_up_sum,
	  SUM(votes_up) AS total_votes_up,
	  SUM(votes_funny) AS total_votes_funny,
	  SUM(comment_count) AS total_comments,
	  MAX(timestamp_created) AS latest_review,
	  MIN(timestamp_created) AS earliest_review,
	  COUNT(DISTINCT author_steamid) AS unique_reviewers,
	  ROUND(AVG(comment_count::NUMERIC),2) AS avg_comment_count
	FROM silver.game_review_stats
	GROUP BY steam_appid;
	
	
	DROP TABLE IF EXISTS gold.fact_reviews CASCADE;
	CREATE TABLE gold.fact_reviews AS
	SELECT
	  id                   AS review_stat_id,
	  recommendation_id,
	  steam_appid          AS game_id,
	  author_steamid       AS author_id,
	  language,
	  timestamp_created,
	  timestamp_updated,
	  voted_up,
	  votes_up,
	  votes_funny,
	  comment_count,
	  steam_purchase,
	  received_for_free,
	  weighted_vote_score,
	  primarily_steam_deck,
	  written_during_early_access
	FROM silver.game_review_stats;
	

	ALTER TABLE gold.dim_games         ADD PRIMARY KEY (game_id);
	ALTER TABLE gold.dim_platforms     ADD PRIMARY KEY (platform_id);
	ALTER TABLE gold.dim_genres        ADD PRIMARY KEY (genre_id);
	ALTER TABLE gold.dim_categories    ADD PRIMARY KEY (category_id);
	ALTER TABLE gold.dim_publishers    ADD PRIMARY KEY (publisher_id);
	ALTER TABLE gold.dim_developers    ADD PRIMARY KEY (developer_id);
	ALTER TABLE gold.dim_rating_agencies ADD PRIMARY KEY (rating_agency_id);
	ALTER TABLE gold.dim_review_authors  ADD PRIMARY KEY (author_id);
	
	
	ALTER TABLE gold.fact_game_platforms
	  ADD CONSTRAINT fact_game_platforms_pk
	    PRIMARY KEY (game_id, platform_id),
	  ADD CONSTRAINT fact_game_platforms_game_id_fkey
	    FOREIGN KEY (game_id) REFERENCES gold.dim_games(game_id),
	  ADD CONSTRAINT fact_game_platforms_platform_id_fkey
	    FOREIGN KEY (platform_id) REFERENCES gold.dim_platforms(platform_id);
	
	ALTER TABLE gold.fact_game_genres
	  ADD PRIMARY KEY (game_id, genre_id);
	
	ALTER TABLE gold.fact_game_categories
	  ADD PRIMARY KEY (game_id, category_id);
	
	ALTER TABLE gold.fact_game_publishers
	  ADD PRIMARY KEY (game_id, publisher_id);
	
	ALTER TABLE gold.fact_game_developers
	  ADD PRIMARY KEY (game_id, developer_id);
	
	ALTER TABLE gold.fact_game_ratings
	  ADD PRIMARY KEY (game_id, rating_agency_id);
	
	ALTER TABLE gold.fact_reviews_agg
	  ADD PRIMARY KEY (game_id);

	
	CREATE INDEX idx_fact_game_platforms_game_id ON gold.fact_game_platforms (game_id);
	CREATE INDEX idx_fact_game_genres_game_id   ON gold.fact_game_genres (game_id);
	
	CREATE INDEX idx_dim_games_type ON gold.dim_games (type);
	CREATE INDEX idx_dim_games_price_final ON gold.dim_games (price_final);
	CREATE INDEX idx_fact_reviews_agg_review_count ON gold.fact_reviews_agg (review_count);


END;
$BODY$;

