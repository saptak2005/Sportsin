-- Migration: user_search_index_indexes (UP)
-- Created: 2025-07-23 20:34:58


-- Index for fast full-text search
CREATE INDEX idx_user_search_vector ON user_search_index USING GIN(search_vector);

-- Indexes for partial/fuzzy search (username and name)
CREATE INDEX idx_user_username_trgm ON user_search_index USING GIN(username gin_trgm_ops);
CREATE INDEX idx_user_name_trgm ON user_search_index USING GIN(name gin_trgm_ops);

