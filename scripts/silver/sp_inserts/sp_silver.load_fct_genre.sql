/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_bridge_genre();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.bridge_genre
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_bridge_genre()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: bridge_genre';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.bridge_genre (steam_appid, genre_id)
	SELECT DISTINCT
	    b.steam_appid,
	    (genre->>'id')::INTEGER AS genre_id
	FROM bronze.steam_app_details AS b,
	     jsonb_array_elements(b.raw_json->'genres') AS genre
	WHERE b.raw_json ? 'genres'
	  AND jsonb_typeof(b.raw_json->'genres') = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
