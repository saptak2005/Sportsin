-- Migration: create_tournament_images_table (UP)
-- Created: 2025-07-13 07:18:12

CREATE TABLE IF NOT EXISTS "TournamentImages" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    FOREIGN KEY (tournament_id) REFERENCES "Tournament"(id) ON DELETE CASCADE
);

