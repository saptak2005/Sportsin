-- Migration: add_title_to_tournament_table (DOWN)
-- Created: 2025-07-13 17:08:56

-- Add your rollback SQL here
-- Example:
-- DROP TABLE IF EXISTS example;

ALTER TABLE "Tournament" DROP COLUMN IF EXISTS title;