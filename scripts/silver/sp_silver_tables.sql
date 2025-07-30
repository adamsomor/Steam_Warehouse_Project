-- PROCEDURE: silver.build_silver_tables()

-- DROP PROCEDURE IF EXISTS silver.build_silver_tables();

CREATE OR REPLACE PROCEDURE silver.build_silver_tables(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
-- Drop tables if exist, order matters due to FK constraints
	DROP TABLE IF EXISTS silver.sat_review_text;
	DROP TABLE IF EXISTS silver.fct_review_stat;
	
	DROP TABLE IF EXISTS silver.bridge_platform;
	
	DROP TABLE IF EXISTS silver.bridge_publisher;
	DROP TABLE IF EXISTS silver.bridge_category;
	DROP TABLE IF EXISTS silver.bridge_genre;
	DROP TABLE IF EXISTS silver.bridge_developer;
	DROP TABLE IF EXISTS silver.fct_rating;
	
	DROP TABLE IF EXISTS silver.hub_author;
	
	DROP TABLE IF EXISTS silver.hub_game;
	
	DROP TABLE IF EXISTS silver.dim_publisher;
	DROP TABLE IF EXISTS silver.dim_category;
	DROP TABLE IF EXISTS silver.dim_genre;
	DROP TABLE IF EXISTS silver.dim_developer;
	DROP TABLE IF EXISTS silver.dim_agency;

/*
===================================================================
1. Dimension tables:
===================================================================
*/

	-- Lookup of publisher names
	CREATE TABLE silver.dim_publisher (
	    publisher_id SERIAL PRIMARY KEY,
	    publisher_name TEXT UNIQUE
	);

	-- Lookup of category names
	CREATE TABLE silver.dim_category (
	    category_id INTEGER PRIMARY KEY,
	    category_description TEXT
	);

	-- Lookup of genre names
	CREATE TABLE silver.dim_genre (
	    genre_id INTEGER PRIMARY KEY,
	    genre_description TEXT UNIQUE
	);

	-- Lookup of developer names
	CREATE TABLE silver.dim_developer (
	    developer_id SERIAL PRIMARY KEY,
	    developer_name TEXT UNIQUE
	);

	-- Lookup of rating agencies: e.g. ESRB, PEGI, DEJUS
	CREATE TABLE silver.dim_agency (
	    rating_agency_id SERIAL PRIMARY KEY,
	    agency_code TEXT UNIQUE NOT NULL  -- e.g. 'esrb', 'dejus'
	);

/*
===================================================================
2. Hub tables:
===================================================================
*/

	-- Core “Author” entity; business‑key (steamid) plus static author attributes
	CREATE TABLE silver.hub_author (
	    steamid BIGINT PRIMARY KEY,
	    num_reviews INTEGER,
	    num_games_owned INTEGER,
	    playtime_forever INTEGER,
	    playtime_at_review INTEGER,
	    playtime_last_two_weeks INTEGER,
	    last_played TIMESTAMP
	);

	-- Core “Game” entity; holds its business‑key (steam_appid) plus static attributes
	CREATE TABLE silver.hub_game (
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
3. Bridge tables (many-to-many, dependent on core + dimensions):
===================================================================
*/

	-- M‑N between Game - Publisher
	CREATE TABLE silver.bridge_publisher (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    publisher_id INTEGER REFERENCES silver.dim_publisher(publisher_id),
	    PRIMARY KEY (steam_appid, publisher_id)
	);

	-- M‑N between Game - Category, no measures, only keys
	CREATE TABLE silver.bridge_category (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    category_id INTEGER REFERENCES silver.dim_category(category_id),
	    PRIMARY KEY (steam_appid, category_id)
	);

	-- M‑N between Game - Genre
	CREATE TABLE silver.bridge_genre (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    genre_id INTEGER REFERENCES silver.dim_genre(genre_id),
	    PRIMARY KEY (steam_appid, genre_id)
	);

	-- M‑N between Game - Developer
	CREATE TABLE silver.bridge_developer (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    developer_id INTEGER REFERENCES silver.dim_developer(developer_id),
	    PRIMARY KEY (steam_appid, developer_id)
	);


	-- M‑N between Game - Platform, no numeric measures
	CREATE TABLE silver.bridge_platform (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    platform TEXT,
	    PRIMARY KEY (steam_appid, platform)
	);
/*
===================================================================
4. Fact Tables
===================================================================
*/

	-- Contains measures (required_age, banned, etc.) linked to Game & Agency
	CREATE TABLE silver.fct_rating (
	    steam_appid INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    rating_agency_id INTEGER REFERENCES silver.dim_agency(rating_agency_id),
	    
	    rating TEXT,                  -- e.g. 'M', '16'
	    required_age INTEGER,
	    banned BOOLEAN,
	    use_age_gate BOOLEAN,
	    rating_generated BOOLEAN,
	    PRIMARY KEY (steam_appid, rating_agency_id)
	);

	-- Numeric measures (votes_up, comment_count, etc.) for each review
	CREATE TABLE IF NOT EXISTS silver.fct_review_stat (
	    id                       BIGSERIAL PRIMARY KEY,
	    recommendation_id        BIGINT NOT NULL,  -- original Steam review ID
	    steam_appid              INTEGER REFERENCES silver.hub_game(steam_appid) ON DELETE CASCADE,
	    author_steamid           BIGINT  REFERENCES silver.hub_author(steamid),
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

/*
===================================================================
5. Satellite tables:
===================================================================
*/

	-- Descriptive text (review_text) tied to a review‑stat record
	CREATE TABLE IF NOT EXISTS silver.sat_review_text (
	    id                   BIGSERIAL PRIMARY KEY,
	    review_stat_rec_id   BIGINT NOT NULL,
	    review_text          TEXT,
	    CONSTRAINT sat_review_text_review_stat_id_fkey FOREIGN KEY (review_stat_rec_id)
	      REFERENCES silver.fct_review_stat(id) ON DELETE CASCADE
	);

	-- Indexes to optimize queries filtering by steam_appid
	CREATE INDEX idx_bridge_category_appid    ON silver.bridge_category   (steam_appid);
	CREATE INDEX idx_bridge_genre_appid        ON silver.bridge_genre       (steam_appid);
	CREATE INDEX idx_bridge_developer_appid    ON silver.bridge_developer   (steam_appid);
	CREATE INDEX idx_fct_rating_appid       ON silver.fct_rating      (steam_appid);
	CREATE INDEX idx_fct_review_stat_appid  ON silver.fct_review_stat (steam_appid);
	CREATE INDEX idx_sat_review_text_by_recid    ON silver.sat_review_text      (review_stat_rec_id);
	-- For common join/lookups
	CREATE INDEX idx_grs_by_recommendation_id ON silver.fct_review_stat(recommendation_id);
	CREATE INDEX idx_grs_by_author           ON silver.fct_review_stat(author_steamid);

END;
$BODY$;
ALTER PROCEDURE silver.build_silver_tables()
    OWNER TO postgres;

