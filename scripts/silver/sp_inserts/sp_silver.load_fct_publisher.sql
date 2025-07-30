/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_bridge_publisher();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.bridge_publisher
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_bridge_publisher()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: bridge_publisher';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

    INSERT INTO silver.bridge_publisher (steam_appid, publisher_id)
    SELECT
        b.steam_appid,
        d.publisher_id
    FROM bronze.steam_app_details AS b
    CROSS JOIN LATERAL jsonb_array_elements_text(b.raw_json->'publishers') AS pub_name
    JOIN silver.dim_publisher d ON d.publisher_name = pub_name
    WHERE b.raw_json ? 'publishers'
      AND jsonb_typeof(b.raw_json->'publishers') = 'array';

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
