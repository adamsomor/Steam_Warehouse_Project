/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_games_master();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.games_master
====================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_games_master(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: games_master';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.games_master (
	    steam_appid,
		name,
		required_age,
		is_free,
		alternate_appid,
		controller_support,
		type,
		
	    price_currency,
		price_initial,
		price_final,
		price_discount_percent,
		
	    metacritic_score,
		
	    recommendation_count,
		
	    release_date,
		coming_soon,
		
	    achievements_total
	)
	SELECT
	    -- 1: Always present
	    steam_appid,
	
	    -- 2: Text fields -> default to empty string
	    COALESCE(NULLIF(raw_json->>'name',''), 'N/A'),
	
	    -- 3: Integers -> default to 0
		COALESCE(
			CASE
				WHEN raw_json->>'required_age' ~ '^[0-9]+$'
				THEN (raw_json->>'required_age')::INTEGER
				ELSE NULL
			END,0),
	
	    -- 4: Boolean -> default to false
	    COALESCE((raw_json->>'is_free')::BOOLEAN, false),
	
	    -- 5: Alternate AppID -> default to 0
	    COALESCE(NULLIF(raw_json->>'alternate_appid','')::INTEGER, 0),
		
		-- 6: Controller support normalization (N/Y/other) → default 'N'
	    	-- Did not find in the data 'partial' or 'no' support
		CASE
			WHEN raw_json->>'controller_support' IS NULL THEN 'N/A'
			WHEN raw_json->>'controller_support' = 'Full' THEN 'Y'
			ELSE raw_json->>'controller_support'
		END,
		
	    -- 7: Type → default to empty string
		COALESCE(NULLIF(raw_json->>'type', ''), 'N/A'),
	
	    -- 8–11: Price overview → default currency 'USD', prices/discount to 0
	    COALESCE(NULLIF(jsonb_extract_path_text(raw_json, 'price_overview', 'currency'),''),'N/A'),
	    COALESCE(NULLIF(jsonb_extract_path_text(raw_json, 'price_overview', 'initial'),'')::INTEGER,0),
	    COALESCE(NULLIF(jsonb_extract_path_text(raw_json, 'price_overview', 'final'),'')::INTEGER,0),
	    COALESCE(NULLIF(jsonb_extract_path_text(raw_json, 'price_overview', 'discount_percent'),'')::INTEGER,0),
	
	    -- 12: Metacritic score → default to 0
	    COALESCE(NULLIF(raw_json->'metacritic'->>'score','')::INTEGER, 0),
	
	    -- 13: Recommendation count → default to 0
	    COALESCE(NULLIF(raw_json->'recommendations'->>'total','')::INTEGER, 0),
		
	    -- 14: Release date → try formats, default to epoch (1970‑01‑01)
		COALESCE(
			CASE
				WHEN raw_json -> 'release_date' ->> 'date' ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
					THEN (raw_json -> 'release_date' ->> 'date')::DATE
				WHEN raw_json -> 'release_date' ->> 'date' ~ '^[A-Za-z]{3} [0-9]{1,2}, [0-9]{4}$'
					THEN TO_DATE(raw_json -> 'release_date' ->> 'date','Mon DD, YYYY')
				ELSE NULL
			END,'1970-01-01'::DATE),
		  
	    -- 15: Coming soon flag → default false
	    COALESCE(NULLIF(raw_json->'release_date'->>'coming_soon','')::BOOLEAN, false),
	
	    -- 16: Achievements total → default to 0
	    COALESCE(NULLIF(raw_json->'achievements'->>'total','')::INTEGER, 0)
	
	FROM bronze.steam_app_details;
	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
