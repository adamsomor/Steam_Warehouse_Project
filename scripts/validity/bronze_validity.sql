------------------------------
-- BRONZE TABLE DUPLICATES
------------------------------

-- CHECK COUNT OF ALL ROWS
SELECT COUNT(*)
FROM bronze.steam_app_details;

-- CHECK COUNT OF DUPLICATES
SELECT COUNT(DISTINCT steam_appid)
FROM bronze.steam_app_details;

------------------------------
-- LOGS DUPLICATES
------------------------------

-- CHECK COUNT OF ALL ROWS
SELECT COUNT(*)
FROM bronze.load_log;

-- CHECK COUNT OF DUPLICATES
SELECT COUNT(DISTINCT steam_appid)
FROM bronze.load_log;

------------------------------
-- CHECK ERRORS
------------------------------

-- SEE ALL LOGS
SELECT COUNT(*), status, error_message, batch_num
FROM bronze.load_log
GROUP BY error_message, status, batch_num
ORDER BY batch_num, status;

-- CHECK SPECIFICALLY FOR 'ERROR' STATUS
SELECT steam_appid, batch_num, status, error_message
FROM bronze.load_log
WHERE status = 'error'

-- CHECK SPECIFICALLY FOR 'NOT INSERTED' STATUS
SELECT COUNT(*), error_message
FROM bronze.load_log
WHERE status <> 'inserted'
GROUP BY error_message

------------------------------
-- TABLE DIFFERENCES
-- BRONZE & LOG
------------------------------

-- CHECK NULLS (MISSING ROWS FROM LOG) IN BRONZE
SELECT r.*
FROM bronze.steam_app_details r
LEFT JOIN bronze.load_log l ON r.steam_appid = l.steam_appid
WHERE l.steam_appid IS NULL;

-- CHECK NULLS (MISSING ROWS FROM BRONZE) IN LOG
SELECT l.*
FROM bronze.load_log l
LEFT JOIN bronze.steam_app_details r ON l.steam_appid = r.steam_appid
WHERE r.steam_appid IS NULL;

------------------------------
-- JSON FILES CHECK
------------------------------

-- CHECK FOR SPECIFIC JSON OBJECT KEY FOR steam_appid
SELECT jsonb_object_keys(raw_json)
FROM bronze.steam_app_details
WHERE steam_appid = 10;

-- Detect rows where 'categories', 'genres', etc., are missing or not arrays
SELECT steam_appid
FROM bronze.steam_app_details
WHERE NOT raw_json ? 'categories'
   OR jsonb_typeof(raw_json->'categories') <> 'array';

-- Detect invalid JSON structure (e.g., not an object at root)
SELECT steam_appid
FROM bronze.steam_app_details
WHERE jsonb_typeof(raw_json) <> 'object';

------------------------------
-- CHECK NULLS
------------------------------

SELECT COUNT(*) AS null_steam_appid
FROM bronze.steam_app_details
WHERE steam_appid IS NULL;

SELECT COUNT(*) AS null_raw_json
FROM bronze.steam_app_details
WHERE raw_json IS NULL;