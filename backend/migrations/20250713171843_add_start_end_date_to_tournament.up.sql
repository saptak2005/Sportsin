-- Migration: add_start_end_date_to_tournament (UP)
-- Created: 2025-07-13 17:18:43

-- Add your SQL migration here
-- Example:
-- CREATE TABLE example (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name VARCHAR(255) NOT NULL
-- );
ALTER TABLE "Tournament" ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE "Tournament" ADD COLUMN IF NOT EXISTS end_date DATE;
