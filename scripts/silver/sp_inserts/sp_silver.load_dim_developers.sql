/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_dim_developers();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.dim_developers
====================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_dim_developers()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: dim_developers';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

    INSERT INTO silver.dim_developers (developer_name)
    SELECT DISTINCT
        jsonb_array_elements_text(raw_json->'developers')
    FROM bronze.steam_app_details
    WHERE raw_json ? 'developers'
      AND jsonb_typeof(raw_json->'developers') = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
