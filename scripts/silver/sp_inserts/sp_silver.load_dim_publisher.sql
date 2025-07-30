/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_dim_publisher();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.dim_publisher
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_dim_publisher()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: dim_publisher';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

    INSERT INTO silver.dim_publisher (publisher_name)
	SELECT DISTINCT
	    publisher
	FROM (
	    SELECT
	        TRIM(jsonb_array_elements_text(raw_json->'publishers')) AS publisher
	    FROM bronze.steam_app_details
	    WHERE raw_json ? 'publishers'
	      AND jsonb_typeof(raw_json->'publishers') = 'array'
	) AS cleaned
	WHERE publisher != ''
	  AND publisher != '-';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
