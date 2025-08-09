-- Migration: create_tournament_participants_table (UP)
-- Created: 2025-07-13 07:17:49

CREATE TABLE IF NOT EXISTS "TournamentParticipant" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tournament_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
    FOREIGN KEY (tournament_id) REFERENCES "Tournament"(id) ON DELETE CASCADE,
    UNIQUE(user_id, tournament_id)
);

