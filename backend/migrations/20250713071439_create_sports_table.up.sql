-- Migration: create_sports_table (UP)
-- Created: 2025-07-13 07:14:39

CREATE TABLE IF NOT EXISTS "Sports" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
);

