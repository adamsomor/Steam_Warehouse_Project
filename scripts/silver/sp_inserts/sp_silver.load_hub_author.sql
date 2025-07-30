/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_hub_author();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.hub_author
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_hub_author()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: hub_author';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.hub_author (
	    steamid,
	    num_reviews,
	    num_games_owned,
	    playtime_forever,
	    playtime_at_review,
	    playtime_last_two_weeks,
	    last_played
	)
	SELECT
	    (rev->'author'->>'steamid')::BIGINT AS steamid,
	    MAX((rev->'author'->>'num_reviews')::INT),
	    MAX((rev->'author'->>'num_games_owned')::INT),
	    MAX((rev->'author'->>'playtime_forever')::INT),
	    MAX((rev->'author'->>'playtime_at_review')::INT),
	    MAX((rev->'author'->>'playtime_last_two_weeks')::INT),
	    MAX(to_timestamp((rev->'author'->>'last_played')::BIGINT))
	FROM bronze.steam_app_details bd
	CROSS JOIN LATERAL jsonb_array_elements(
	    bd.raw_json->'review_stats'->'reviews'
	) AS rev(rev)
	WHERE bd.raw_json ? 'review_stats'
	  AND jsonb_typeof(bd.raw_json->'review_stats'->'reviews') = 'array'
	GROUP BY steamid
	ON CONFLICT (steamid) DO UPDATE
	  SET
	    num_reviews = EXCLUDED.num_reviews,
	    num_games_owned = EXCLUDED.num_games_owned,
	    playtime_forever = EXCLUDED.playtime_forever,
	    playtime_at_review = EXCLUDED.playtime_at_review,
	    playtime_last_two_weeks = EXCLUDED.playtime_last_two_weeks,
	    last_played = EXCLUDED.last_played;

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete: % (took % seconds)', end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete: % (took % seconds)', end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
