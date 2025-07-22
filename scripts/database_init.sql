/* ====================================================
			DATABASE INITIALISATION

====================================================

Drop and recreate the database (optional and destructive)
Only run this section if you are sure you want to recreate it from scratch
====================================================
*/

-- DROP DATABASE IF EXISTS steam_data;

CREATE DATABASE steam_data
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- ============================================
-- Create Schemas: bronze, silver, gold
-- ============================================

CREATE SCHEMA IF NOT EXISTS bronze AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS silver AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS gold AUTHORIZATION postgres;
