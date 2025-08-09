-- Migration: user_search_index_indexes (DOWN)
-- Created: 2025-07-23 20:34:58



DROP INDEX IF EXISTS idx_user_search_vector;
DROP INDEX IF EXISTS idx_user_username_trgm;
DROP INDEX IF EXISTS idx_user_name_trgm;
