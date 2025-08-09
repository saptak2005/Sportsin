-- Migration: create_tournament_table (UP)
-- Created: 2025-07-13 07:17:23

CREATE TABLE IF NOT EXISTS "Tournament" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255) NOT NULL,
    sport_id UUID NOT NULL,
    min_age INT NOT NULL,
    max_age INT NOT NULL,
    level VARCHAR(50) NOT NULL,
    level_location VARCHAR(255) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    country_restriction VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'ongoing',
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    banner_link VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (host_id) REFERENCES "User"(id) ON DELETE CASCADE,
    FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE
);

