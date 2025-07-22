/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_game_categories();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.game_categories
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_game_categories()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: game_categories';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';
	
	INSERT INTO silver.game_categories (steam_appid, category_id)
	SELECT DISTINCT
	    bd.steam_appid,
	    (category->>'id')::INTEGER
	FROM bronze.steam_app_details bd
	CROSS JOIN LATERAL jsonb_array_elements(bd.raw_json->'categories') AS category
	WHERE bd.raw_json ? 'categories';
	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
