/*
====================================================
				STORED PROCEDURE
				  TRUNCATE DATA
====================================================
To execute run:
		CALL silver.truncate_all_data();
		
====================================================
It truncates all data from the silver scheme
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.truncate_all_data()
LANGUAGE plpgsql
AS $BODY$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'TRUNCATING ALL DATA FROM SILVER';
    RAISE NOTICE '================================================';

	-- Step 1: Truncate most dependent tables first
	TRUNCATE TABLE
	    silver.game_reviews,
	    silver.game_review_stats,
	    silver.game_platforms,
	    silver.game_ratings,
	    silver.game_developers,
	    silver.game_genres,
	    silver.game_categories,
	    silver.game_publishers
	CASCADE;
	
	-- Step 2: Truncate core game table
	TRUNCATE TABLE silver.games_master CASCADE;
	
	-- Step 3: Truncate review authors
	TRUNCATE TABLE silver.review_authors CASCADE;
	
	-- Step 4: Truncate dimensions last
	TRUNCATE TABLE
	    silver.dim_rating_agencies,
	    silver.dim_developers,
	    silver.dim_genres,
	    silver.dim_categories,
	    silver.dim_publishers
	RESTART IDENTITY CASCADE;

END
$BODY$
