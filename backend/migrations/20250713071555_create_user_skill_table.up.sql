-- Migration: create_user_skill_table (UP)
-- Created: 2025-07-13 07:15:55

CREATE TABLE IF NOT EXISTS "UserSkill" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    sport_id UUID NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
    FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE
);

