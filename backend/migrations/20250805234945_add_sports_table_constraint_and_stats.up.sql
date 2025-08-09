-- Migration: add_sports_table_constraint_and_stats (UP)
-- Created: 2025-08-05 23:49:45

ALTER TABLE "Sports" ADD CONSTRAINT "Sports_name_key" UNIQUE (name);
ALTER TABLE "Sports" ADD INDEX "name";

