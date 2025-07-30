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
	    silver.sat_review_text,
	    silver.fct_review_stat,
	    silver.bridge_platform,
	    silver.fct_rating,
	    silver.bridge_developer,
	    silver.bridge_genre,
	    silver.bridge_category,
	    silver.bridge_publisher
	CASCADE;
	
	-- Step 2: Truncate core game table
	TRUNCATE TABLE silver.hub_game CASCADE;
	
	-- Step 3: Truncate review authors
	TRUNCATE TABLE silver.hub_author CASCADE;
	
	-- Step 4: Truncate dimensions last
	TRUNCATE TABLE
	    silver.dim_agency,
	    silver.dim_developer,
	    silver.dim_genre,
	    silver.dim_category,
	    silver.dim_publisher
	RESTART IDENTITY CASCADE;

END
$BODY$
