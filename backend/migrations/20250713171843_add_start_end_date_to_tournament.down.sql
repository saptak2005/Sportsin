-- Migration: add_start_end_date_to_tournament (DOWN)
-- Created: 2025-07-13 17:18:43

-- Add your rollback SQL here
-- Example:
-- DROP TABLE IF EXISTS example;

ALTER TABLE "Tournament" DROP COLUMN IF EXISTS start_date;
ALTER TABLE "Tournament" DROP COLUMN IF EXISTS end_date;