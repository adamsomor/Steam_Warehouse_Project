/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_game_reviews();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.game_reviews
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_game_reviews()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: game_reviews';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.game_reviews (
	    review_stat_rec_id,
	    review_text
	)
	SELECT
	    grs.id,  -- from matched record in game_review_stats
	    rev->>'review'
	FROM bronze.steam_app_details bd
	CROSS JOIN LATERAL jsonb_array_elements(
	    bd.raw_json->'review_stats'->'reviews'
	) AS rev(rev)
	JOIN silver.game_review_stats grs
	  ON grs.recommendation_id = (rev->>'recommendationid')::BIGINT
	WHERE bd.raw_json ? 'review_stats'
	  AND jsonb_typeof(bd.raw_json->'review_stats'->'reviews') = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete: % (took % seconds)', end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
