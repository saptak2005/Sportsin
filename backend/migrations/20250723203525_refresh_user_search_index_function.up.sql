-- Migration: refresh_user_search_index_function (UP)
-- Created: 2025-07-23 20:35:25


CREATE OR REPLACE FUNCTION refresh_user_search_index()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY user_search_index;
END;
$$ LANGUAGE plpgsql;
