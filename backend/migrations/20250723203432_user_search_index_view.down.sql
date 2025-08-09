-- Migration: user_search_index_view (DOWN)
-- Created: 2025-07-23 20:34:32

DROP MATERIALIZED VIEW IF EXISTS user_search_index;
DROP EXTENSION IF EXISTS pg_trgm;

