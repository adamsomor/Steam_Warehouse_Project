/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_game_genres();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.game_genres
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_game_genres()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: game_genres';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.game_genres (steam_appid, genre_id)
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
