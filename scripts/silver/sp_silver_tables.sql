-- PROCEDURE: silver.rebuild_all_tables()

-- DROP PROCEDURE IF EXISTS silver.rebuild_all_tables();

CREATE OR REPLACE PROCEDURE build_silver_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
-- Drop tables if exist, order matters due to FK constraints
	DROP TABLE IF EXISTS silver.game_reviews;
	DROP TABLE IF EXISTS silver.game_review_stats;
	
	DROP TABLE IF EXISTS silver.game_platforms;
	
	DROP TABLE IF EXISTS silver.game_publishers;
	DROP TABLE IF EXISTS silver.game_categories;
	DROP TABLE IF EXISTS silver.game_genres;
	DROP TABLE IF EXISTS silver.game_developers;
	DROP TABLE IF EXISTS silver.game_ratings;
	
	DROP TABLE IF EXISTS silver.review_authors;
	
	DROP TABLE IF EXISTS silver.games_master;
	
	DROP TABLE IF EXISTS silver.dim_publishers;
	DROP TABLE IF EXISTS silver.dim_categories;
	DROP TABLE IF EXISTS silver.dim_genres;
	DROP TABLE IF EXISTS silver.dim_developers;
	DROP TABLE IF EXISTS silver.dim_rating_agencies;

	EXECUTE 'CREATE SCHEMA IF NOT EXISTS silver';

/*
===================================================================
1. Dimension tables (independent):
===================================================================
*/

	-- Publishers dimension table; unique list of all publishers
	CREATE TABLE silver.dim_publishers (
	    publisher_id SERIAL PRIMARY KEY,
	    publisher_name TEXT UNIQUE
	);

	-- Categories dimension table; unique list of all categories
	CREATE TABLE silver.dim_categories (
	    category_id INTEGER PRIMARY KEY,
	    category_description TEXT
	);

	-- Genres dimension table; unique list of all genres
	CREATE TABLE silver.dim_genres (
	    genre_id INTEGER PRIMARY KEY,
	    genre_description TEXT UNIQUE
	);

	-- Developers dimension table; unique list of all developers
	CREATE TABLE silver.dim_developers (
	    developer_id SERIAL PRIMARY KEY,
	    developer_name TEXT UNIQUE
	);

	-- Rating agencies dimension table; e.g. ESRB, PEGI, DEJUS
	CREATE TABLE silver.dim_rating_agencies (
	    rating_agency_id SERIAL PRIMARY KEY,
	    agency_code TEXT UNIQUE NOT NULL  -- e.g. 'esrb', 'dejus'
	);

/*
===================================================================
2. Author lookup
===================================================================
*/

	-- Author metadata for reviewers
	CREATE TABLE silver.review_authors (
	    steamid BIGINT PRIMARY KEY,
	    num_reviews INTEGER,
	    num_games_owned INTEGER,
	    playtime_forever INTEGER,
	    playtime_at_review INTEGER,
	    playtime_last_two_weeks INTEGER,
	    last_played TIMESTAMP
	);

/*
===================================================================
3. Core game table:
===================================================================
*/

	-- Main game details table; stores core attributes of each game
	CREATE TABLE silver.games_master (
	    steam_appid INTEGER PRIMARY KEY,
	    name TEXT,
	    required_age INTEGER,
	    is_free BOOLEAN,
	    alternate_appid INTEGER,
	    controller_support TEXT,
	    type TEXT,
	    
	    price_currency TEXT,
	    price_initial INTEGER,
	    price_final INTEGER,
	    price_discount_percent INTEGER,

	    metacritic_score INTEGER,

	    recommendation_count INTEGER,

	    release_date DATE,
	    coming_soon BOOLEAN,

	    achievements_total INTEGER
	);

/*
===================================================================
4. Bridge tables (many-to-many, dependent on core + dimensions):
===================================================================
*/

	-- Bridge table linking games to publishers (many-to-many)
	CREATE TABLE silver.game_publishers (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    publisher_id INTEGER REFERENCES silver.dim_publishers(publisher_id),
	    PRIMARY KEY (steam_appid, publisher_id)
	);

	-- Bridge table linking games to categories (many-to-many)
	CREATE TABLE silver.game_categories (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    category_id INTEGER REFERENCES silver.dim_categories(category_id),
	    PRIMARY KEY (steam_appid, category_id)
	);

	-- Bridge table linking games to genres (many-to-many)
	CREATE TABLE silver.game_genres (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    genre_id INTEGER REFERENCES silver.dim_genres(genre_id),
	    PRIMARY KEY (steam_appid, genre_id)
	);

	-- Bridge table linking games to developers (many-to-many)
	CREATE TABLE silver.game_developers (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    developer_id INTEGER REFERENCES silver.dim_developers(developer_id),
	    PRIMARY KEY (steam_appid, developer_id)
	);

	-- Bridge table linking games to various agencies
	CREATE TABLE silver.game_ratings (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    rating_agency_id INTEGER REFERENCES silver.dim_rating_agencies(rating_agency_id),
	    
	    rating TEXT,                  -- e.g. 'M', '16'
	    required_age INTEGER,
	    banned BOOLEAN,
	    use_age_gate BOOLEAN,
	    rating_generated BOOLEAN,
	    PRIMARY KEY (steam_appid, rating_agency_id)
	);

/*
===================================================================
5. Other dependent tables
===================================================================
*/

	-- Platforms supported by each game (depends on games_master)
	CREATE TABLE silver.game_platforms (
	    steam_appid INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    platform TEXT,
	    PRIMARY KEY (steam_appid, platform)
	);

	-- Metadata for user reviews of games (depends on games_master and review_authors)
	CREATE TABLE IF NOT EXISTS silver.game_review_stats (
	    id                       BIGSERIAL PRIMARY KEY,
	    recommendation_id        BIGINT NOT NULL,  -- original Steam review ID
	    steam_appid              INTEGER REFERENCES silver.games_master(steam_appid) ON DELETE CASCADE,
	    author_steamid           BIGINT  REFERENCES silver.review_authors(steamid),
	    language                 TEXT,
	    timestamp_created        TIMESTAMP,
	    timestamp_updated        TIMESTAMP,
	    voted_up                 BOOLEAN,
	    votes_up                 BIGINT,
	    votes_funny              BIGINT,
	    comment_count            BIGINT,
	    steam_purchase           BOOLEAN,
	    received_for_free        BOOLEAN,
	    weighted_vote_score      REAL,
	    primarily_steam_deck     BOOLEAN,
	    written_during_early_access BOOLEAN
	);

	-- Review text body (depends on game_review_stats)
	CREATE TABLE IF NOT EXISTS silver.game_reviews (
	    id                   BIGSERIAL PRIMARY KEY,
	    review_stat_rec_id   BIGINT NOT NULL,
	    review_text          TEXT,
	    CONSTRAINT game_reviews_review_stat_id_fkey FOREIGN KEY (review_stat_rec_id)
	      REFERENCES silver.game_review_stats(id) ON DELETE CASCADE
	);

	-- Indexes to optimize queries filtering by steam_appid
	CREATE INDEX idx_game_categories_appid    ON silver.game_categories   (steam_appid);
	CREATE INDEX idx_game_genres_appid        ON silver.game_genres       (steam_appid);
	CREATE INDEX idx_game_developers_appid    ON silver.game_developers   (steam_appid);
	CREATE INDEX idx_game_ratings_appid       ON silver.game_ratings      (steam_appid);
	CREATE INDEX idx_game_review_stats_appid  ON silver.game_review_stats (steam_appid);
	CREATE INDEX idx_game_reviews_by_recid    ON silver.game_reviews      (review_stat_rec_id);
	-- For common join/lookups
	CREATE INDEX idx_grs_by_recommendation_id ON silver.game_review_stats(recommendation_id);
	CREATE INDEX idx_grs_by_author           ON silver.game_review_stats(author_steamid);

END;
$BODY$;
ALTER PROCEDURE silver.rebuild_all_tables()
    OWNER TO postgres;

