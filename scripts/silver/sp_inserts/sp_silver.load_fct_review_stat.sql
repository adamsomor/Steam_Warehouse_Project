/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_fct_review_stat();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.fct_review_stat
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_fct_review_stat()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: fct_review_stat';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

    INSERT INTO silver.fct_review_stat (
        recommendation_id,
        steam_appid,
        language,
        timestamp_created,
        timestamp_updated,
        author_steamid,
        voted_up,
        votes_up,
        votes_funny,
        comment_count,
        steam_purchase,
        received_for_free,
        weighted_vote_score,
        primarily_steam_deck,
        written_during_early_access
    )
    SELECT
        (rev->>'recommendationid')::BIGINT,
        bd.steam_appid,
        rev->>'language',
        to_timestamp((rev->>'timestamp_created')::BIGINT),
        to_timestamp((rev->>'timestamp_updated')::BIGINT),
        (rev->'author'->>'steamid')::BIGINT,
        (rev->>'voted_up')::BOOLEAN,
        (rev->>'votes_up')::BIGINT,
	CASE
	  WHEN (rev->>'votes_funny')::BIGINT = 4294967295 THEN NULL
	  ELSE (rev->>'votes_funny')::BIGINT
	END AS votes_funny,
        (rev->>'comment_count')::BIGINT,
        (rev->>'steam_purchase')::BOOLEAN,
        (rev->>'received_for_free')::BOOLEAN,
        NULLIF(rev->>'weighted_vote_score','')::REAL,
        (rev->>'primarily_steam_deck')::BOOLEAN,
        (rev->>'written_during_early_access')::BOOLEAN
    FROM bronze.steam_app_details bd
    CROSS JOIN LATERAL jsonb_array_elements(
        bd.raw_json->'review_stats'->'reviews'
    ) AS rev(rev)
    WHERE bd.raw_json ? 'review_stats'
      AND jsonb_typeof(
        bd.raw_json->'review_stats'->'reviews'
      ) = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete: % (took % seconds)', end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
