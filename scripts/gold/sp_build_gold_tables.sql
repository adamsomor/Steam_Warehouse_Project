-- PROCEDURE: public.build_gold_tables()

-- DROP PROCEDURE IF EXISTS public.build_gold_tables();

CREATE OR REPLACE PROCEDURE gold.build_gold_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	
	DROP TABLE IF EXISTS gold.hub_game CASCADE;
	CREATE TABLE gold.hub_game AS
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
	FROM silver.hub_game;
	
	
	DROP TABLE IF EXISTS gold.bridge_platform CASCADE;
	CREATE TABLE gold.bridge_platform AS
	WITH uniq AS (
	  SELECT DISTINCT platform
	  FROM silver.bridge_platform
	)
	SELECT
	  ROW_NUMBER() OVER (ORDER BY platform) AS platform_id,
	  platform
	FROM uniq;

	
	DROP TABLE IF EXISTS gold.dim_genr CASCADE;
	CREATE TABLE gold.dim_genr AS
	SELECT
	  genre_id,
	  genre_description
	FROM silver.dim_genre;
	
	
	DROP TABLE IF EXISTS gold.dim_category CASCADE;
	CREATE TABLE gold.dim_category AS
	SELECT
	  category_id,
	  category_description
	FROM silver.dim_category;
	
	
	DROP TABLE IF EXISTS gold.dim_publisher CASCADE;
	CREATE TABLE gold.dim_publisher AS
	SELECT
	  publisher_id,
	  publisher_name
	FROM silver.dim_publisher;
	
	
	DROP TABLE IF EXISTS gold.dim_developer CASCADE;
	CREATE TABLE gold.dim_developer AS
	SELECT
	  developer_id,
	  developer_name
	FROM silver.dim_developer;
	
	
	DROP TABLE IF EXISTS gold.dim_agency CASCADE;
	CREATE TABLE gold.dim_agency AS
	SELECT
	  rating_agency_id,
	  agency_code
	FROM silver.dim_agency;
	
	
	DROP TABLE IF EXISTS gold.hub_author CASCADE;
	CREATE TABLE gold.hub_author AS
	SELECT
	  steamid       AS author_id,
	  num_reviews,
	  num_games_owned,
	  playtime_forever,
	  playtime_at_review,
	  playtime_last_two_weeks,
	  last_played
	FROM silver.hub_author;
	

	DROP TABLE IF EXISTS gold.bridge_platform CASCADE;
	CREATE TABLE gold.bridge_platform AS
	SELECT
	  gp.steam_appid AS game_id,
	  dp.platform_id
	FROM silver.bridge_platform gp
	  JOIN gold.bridge_platform dp
	    ON gp.platform = dp.platform
	;

	
	DROP TABLE IF EXISTS gold.bridge_genre CASCADE;
	CREATE TABLE gold.bridge_genre AS
	SELECT
	  steam_appid AS game_id,
	  genre_id
	FROM silver.bridge_genre;
	
	
	DROP TABLE IF EXISTS gold.bridge_category CASCADE;
	CREATE TABLE gold.bridge_category AS
	SELECT
	  steam_appid  AS game_id,
	  category_id
	FROM silver.bridge_category;
	
	
	DROP TABLE IF EXISTS gold.bridge_publisher CASCADE;
	CREATE TABLE gold.bridge_publisher AS
	SELECT
	  steam_appid   AS game_id,
	  publisher_id
	FROM silver.bridge_publisher;
	
	
	DROP TABLE IF EXISTS gold.bridge_developer CASCADE;
	CREATE TABLE gold.bridge_developer AS
	SELECT
	  steam_appid   AS game_id,
	  developer_id
	FROM silver.bridge_developer;
	
	
	-- Here we aggregate ratings per game and agency just in case multiple rows exist
	DROP TABLE IF EXISTS gold.fct_rating CASCADE;
	CREATE TABLE gold.fct_rating AS
	SELECT
	  steam_appid AS game_id,
	  rating_agency_id,
	  MAX(rating)            AS rating,
	  MAX(required_age)      AS required_age,
	  BOOL_OR(banned)        AS banned,
	  BOOL_OR(use_age_gate)  AS use_age_gate,
	  BOOL_OR(rating_generated) AS rating_generated
	FROM silver.fct_rating
	GROUP BY steam_appid, rating_agency_id;
	
	
	DROP TABLE IF EXISTS gold.fct_review_agg CASCADE;
	CREATE TABLE gold.fct_review_stat AS
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
	FROM silver.fct_review_stat
	GROUP BY steam_appid;
	
	
	DROP TABLE IF EXISTS gold.fct_review_stat CASCADE;
	CREATE TABLE gold.fct_review_stat AS
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
	FROM silver.fct_review_stat;
	

	ALTER TABLE gold.hub_game         ADD PRIMARY KEY (game_id);
	ALTER TABLE gold.bridge_platform     ADD PRIMARY KEY (platform_id);
	ALTER TABLE gold.dim_genre        ADD PRIMARY KEY (genre_id);
	ALTER TABLE gold.dim_category    ADD PRIMARY KEY (category_id);
	ALTER TABLE gold.dim_publisher    ADD PRIMARY KEY (publisher_id);
	ALTER TABLE gold.dim_developer    ADD PRIMARY KEY (developer_id);
	ALTER TABLE gold.dim_agency ADD PRIMARY KEY (rating_agency_id);
	ALTER TABLE gold.dim_hub_author  ADD PRIMARY KEY (author_id);
	
	
	ALTER TABLE gold.bridge_platform
	  ADD CONSTRAINT bridge_platform_pk
	    PRIMARY KEY (game_id, platform_id),
	  ADD CONSTRAINT bridge_platform_game_id_fkey
	    FOREIGN KEY (game_id) REFERENCES gold.hub_game(game_id),
	  ADD CONSTRAINT bridge_platform_platform_id_fkey
	    FOREIGN KEY (platform_id) REFERENCES gold.bridge_platform(platform_id);
	
	ALTER TABLE gold.bridge_genre
	  ADD PRIMARY KEY (game_id, genre_id);
	
	ALTER TABLE gold.bridge_category
	  ADD PRIMARY KEY (game_id, category_id);
	
	ALTER TABLE gold.bridge_publisher
	  ADD PRIMARY KEY (game_id, publisher_id);
	
	ALTER TABLE gold.bridge_developer
	  ADD PRIMARY KEY (game_id, developer_id);
	
	ALTER TABLE gold.fct_rating
	  ADD PRIMARY KEY (game_id, rating_agency_id);
	
	ALTER TABLE gold.fct_review_agg
	  ADD PRIMARY KEY (game_id);

	
	CREATE INDEX idx_bridge_platform_game_id ON gold.bridge_platform (game_id);
	CREATE INDEX idx_bridge_genre_game_id   ON gold.bridge_genre (game_id);
	
	CREATE INDEX idx_hub_game_type ON gold.hub_game (type);
	CREATE INDEX idx_hub_game_price_final ON gold.hub_game (price_final);
	CREATE INDEX idx_fct_review_agg_review_count ON gold.fct_review_agg (review_count);


END;
$BODY$;

