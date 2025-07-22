/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_game_developers();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.game_developers
====================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_game_developers()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: game_developers';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.game_developers (steam_appid, developer_id)
	SELECT DISTINCT
	    b.steam_appid,
	    d.developer_id
	FROM bronze.steam_app_details AS b
	CROSS JOIN LATERAL jsonb_array_elements_text(b.raw_json->'developers') AS dev_name
	JOIN silver.dim_developers d ON d.developer_name = dev_name
	WHERE b.raw_json ? 'developers'
	  AND jsonb_typeof(b.raw_json->'developers') = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
