-- Migration: create_application_table (UP)
-- Created: 2025-07-19 20:48:10

CREATE TABLE IF NOT EXISTS "Application" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL,
  opening_id UUID NOT NULL,
  status VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  FOREIGN KEY (player_id) REFERENCES "Player"(id),
  FOREIGN KEY (opening_id) REFERENCES "Opening"(id)
  );
