/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_game_platforms();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.game_platforms
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_game_platforms()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: game_platforms';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';
	
	INSERT INTO silver.game_platforms (
	    steam_appid,
	    platform
	)
	SELECT
	    steam_appid,
	    jsonb_object_keys(raw_json->'platforms') AS platform
	FROM bronze.steam_app_details
	WHERE raw_json ? 'platforms';

	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
