/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_dim_category();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.dim_category
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_dim_category()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: dim_category';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';
	
	INSERT INTO silver.dim_category (category_id, category_description)
	WITH all_cats AS (
	  SELECT
	    (elem->>'id')::INT AS category_id,
	    elem->>'description'   AS category_description
	  FROM bronze.steam_app_details bd
	  CROSS JOIN LATERAL jsonb_array_elements(bd.raw_json->'categories') AS cat(elem)
	  WHERE bd.raw_json ? 'categories'
	),
	ranked AS (
	  SELECT
	    category_id,
	    category_description,
	    -- score = 0 for ASCII-only (likely English), 1 otherwise
	    ROW_NUMBER() OVER (
	      PARTITION BY category_id 
	      ORDER BY 
	        (category_description ~ '^[\x00-\x7F]+$') DESC
	    ) AS rn
	  FROM all_cats
	)
	SELECT
	  category_id,
	  category_description
	FROM ranked
	WHERE rn = 1
	ON CONFLICT (category_id) DO UPDATE
	  SET category_description = EXCLUDED.category_description;
	
    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
