/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_dim_agency();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.dim_agency
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_dim_agency()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: dim_agency';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

    INSERT INTO silver.dim_agency (agency_code)
    SELECT DISTINCT jsonb_object_keys(raw_json->'ratings')
    FROM bronze.steam_app_details
    WHERE raw_json ? 'ratings'
      AND jsonb_typeof(raw_json->'ratings') = 'object';

	end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);

END;
$BODY$;
