/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_fct_rating();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.fct_rating
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_fct_rating()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: fct_rating';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.fct_rating (
	    steam_appid,
	    rating_agency_id,
	    rating,
	    required_age,
	    banned,
	    use_age_gate,
	    rating_generated
	)
	SELECT
	    b.steam_appid,
	    a.rating_agency_id,
	    rating_val->>'rating' AS rating,
	
	    -- Safely cast required_age only if all digits
	    CASE
	      WHEN rating_val->>'required_age' ~ '^[0-9]+$'
	      THEN (rating_val->>'required_age')::INT
	      ELSE NULL
	    END AS required_age,
	
	    CASE
	      WHEN rating_val->>'banned' IN ('0','1','true','false')
	      THEN (rating_val->>'banned')::BOOLEAN
	      ELSE NULL
	    END AS banned,
	
	    CASE
	      WHEN rating_val->>'use_age_gate' IN ('0','1','true','false')
	      THEN (rating_val->>'use_age_gate')::BOOLEAN
	      ELSE NULL
	    END AS use_age_gate,
	
	    CASE
	      WHEN rating_val->>'rating_generated' IN ('0','1','true','false')
	      THEN (rating_val->>'rating_generated')::BOOLEAN
	      ELSE NULL
	    END AS rating_generated
	
	FROM bronze.steam_app_details AS b
	CROSS JOIN LATERAL jsonb_each(b.raw_json->'ratings') AS rating_info(agency_code, rating_val)
	JOIN silver.dim_agency a
	  ON a.agency_code = rating_info.agency_code
	WHERE b.raw_json ? 'ratings'
	  AND jsonb_typeof(b.raw_json->'ratings') = 'object'
	  AND (
	      rating_val->>'rating'            IS NOT NULL
	   OR rating_val->>'required_age'     IS NOT NULL
	   OR rating_val->>'banned'           IS NOT NULL
	   OR rating_val->>'use_age_gate'     IS NOT NULL
	   OR rating_val->>'rating_generated' IS NOT NULL
	);
	
	end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
