-- Migration: create_achievements_table (UP)
-- Created: 2025-07-13 07:16:17

CREATE TABLE IF NOT EXISTS "Achievements" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    date DATE NOT NULL,
    sport_id UUID NOT NULL,
    tournament_title VARCHAR(255) NOT NULL,
    description TEXT,
    level VARCHAR(50) NOT NULL,
    stats JSONB,
    certificate_link VARCHAR(500),
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
    FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE
);

