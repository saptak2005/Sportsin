-- Migration: add_title_to_tournament_table (UP)
-- Created: 2025-07-13 17:08:56

-- Add your SQL migration here
-- Example:
-- CREATE TABLE example (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name VARCHAR(255) NOT NULL
-- );
ALTER TABLE "Tournament" ADD COLUMN IF NOT EXISTS title VARCHAR(255);