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
	CALL silver.load_dim_publisher();
    RAISE NOTICE '<< Completed dim_publisher';

	CALL silver.load_dim_category();
    RAISE NOTICE '<< Completed dim_category';

	CALL silver.load_dim_genre();
    RAISE NOTICE '<< Completed dim_genre';

	CALL silver.load_dim_developer();
    RAISE NOTICE '<< Completed dim_developer';

	CALL silver.load_dim_agency();
    RAISE NOTICE '<< Completed dim_agency';

	CALL silver.load_hub_author();
    RAISE NOTICE '<< Completed hub_author';

	CALL silver.load_hub_game();
    RAISE NOTICE '<< Completed hub_game';

	CALL silver.load_bridge_publisher();
    RAISE NOTICE '<< Completed bridge_publisher';

	CALL silver.load_bridge_category();
    RAISE NOTICE '<< Completed bridge_categorie';

	CALL silver.load_bridge_genre();
    RAISE NOTICE '<< Completed bridge_genre';

	CALL silver.load_bridge_developer();
    RAISE NOTICE '<< Completed bridge_developer';

	CALL silver.load_fct_rating();
    RAISE NOTICE '<< Completed fct_rating';

	CALL silver.load_bridge_platform();
    RAISE NOTICE '<< Completed bridge_platform';

	CALL silver.load_fct_review_stat();
    RAISE NOTICE '<< Completed fct_review_stat';
	
	CALL silver.load_sat_review_text();
    RAISE NOTICE '<< Completed sat_review_text';
	
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Full SILVER layer load complete';
    RAISE NOTICE '================================================';
	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
