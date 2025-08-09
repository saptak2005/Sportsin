-- Migration: add_sports_table_constraint_and_stats (DOWN)
-- Created: 2025-08-05 23:49:45


ALTER TABLE "Sports" DROP INDEX "Sports_name_idx";
ALTER TABLE "Sports" DROP CONSTRAINT "Sports_name_key";
