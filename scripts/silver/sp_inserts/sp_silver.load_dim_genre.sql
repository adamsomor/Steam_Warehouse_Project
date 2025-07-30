/*
====================================================
				STORED PROCEDURE
					LOAD DATA
====================================================
To execute run:
		CALL silver.load_dim_genre();
		
====================================================
It loads data from the table
		'bronze.steam_app_details'
			into silver.dim_genre
====================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_dim_genre()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer: dim_genre';
    RAISE NOTICE '================================================';

    start_time := clock_timestamp();

    RAISE NOTICE 'Starting to load . . ';

	INSERT INTO silver.dim_genre (genre_id, genre_description)
	SELECT DISTINCT
	  (elem->>'id')::INTEGER AS genre_id,
	  elem->>'description'    AS genre_description
	FROM bronze.steam_app_details bd
	CROSS JOIN LATERAL jsonb_array_elements(bd.raw_json->'genres') AS g(elem)
	WHERE bd.raw_json ? 'genres'
	  AND jsonb_typeof(bd.raw_json->'genres') = 'array'
	  AND elem->>'description' IN (
	    'Action',
	    'Strategy',
	    'RPG',
	    'Simulation',
	    'Indie',
	    'Sports',
	    'Racing',
	    'Adventure',
	    'Casual',
	    'Free To Play',
	    'Massively Multiplayer',
	    'Accounting',
	    'Animation & Modeling',
	    'Audio Production',
	    'Design & Illustration',
	    'Education',
	    'Photo Editing',
	    'Software Training',
	    'Utilities',
	    'Video Production',
	    'Web Publishing',
	    'Game Development',
	    'Early Access',
	    'Sexual Content',
	    'Nudity',
	    'Violent',
	    'Gore',
	    'Movie',
	    'Documentary',
	    'Short'
	  )
	ON CONFLICT (genre_id) DO UPDATE
	  SET genre_description = EXCLUDED.genre_description;

    end_time := clock_timestamp();
    RAISE NOTICE 'Load complete at % (took % seconds)',
                 end_time,
                 EXTRACT(EPOCH FROM end_time - start_time);
END;
$BODY$;
