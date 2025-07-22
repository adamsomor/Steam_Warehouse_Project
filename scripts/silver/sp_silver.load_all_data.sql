/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_all_data();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver layer
====================================================




====================================================
					WARNINIG
	This load can take a really long time!
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_all_data(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Starting full SILVER layer load';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();
	CALL silver.load_dim_publishers();
    RAISE NOTICE '<< Completed dim_publishers';

	CALL silver.load_dim_categories();
    RAISE NOTICE '<< Completed dim_categories';

	CALL silver.load_dim_genres();
    RAISE NOTICE '<< Completed dim_genres';

	CALL silver.load_dim_developers();
    RAISE NOTICE '<< Completed dim_developers';

	CALL silver.load_dim_rating();
    RAISE NOTICE '<< Completed dim_rating_agencies';

	CALL silver.load_review_authors();
    RAISE NOTICE '<< Completed review_authors';

	CALL silver.load_games_master();
    RAISE NOTICE '<< Completed games_master';

	CALL silver.load_game_publishers();
    RAISE NOTICE '<< Completed game_publishers';

	CALL silver.load_game_categories();
    RAISE NOTICE '<< Completed game_categories';

	CALL silver.load_game_genres();
    RAISE NOTICE '<< Completed game_genres';

	CALL silver.load_game_developers();
    RAISE NOTICE '<< Completed game_developers';

	CALL silver.load_game_ratings();
    RAISE NOTICE '<< Completed game_ratings';

	CALL silver.load_game_platforms();
    RAISE NOTICE '<< Completed game_platforms';

	CALL silver.load_game_review_stats();
    RAISE NOTICE '<< Completed game_review_stats';
	
	CALL silver.load_game_reviews();
    RAISE NOTICE '<< Completed game_reviews';
	
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Full SILVER layer load complete';
    RAISE NOTICE '================================================';
	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
