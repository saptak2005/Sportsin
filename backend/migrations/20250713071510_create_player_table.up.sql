-- Migration: create_player_table (UP)
-- Created: 2025-07-13 07:15:10

CREATE TABLE IF NOT EXISTS "Player" (
    id UUID PRIMARY KEY,
    level VARCHAR(50) NOT NULL,
    interest VARCHAR(500) NOT NULL,
    interest_country VARCHAR(100),
    FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
);

