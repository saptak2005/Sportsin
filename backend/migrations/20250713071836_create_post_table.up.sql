-- Migration: create_post_table (UP)
-- Created: 2025-07-13 07:18:36

CREATE TABLE IF NOT EXISTS "Post" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    created_at DATE NOT NULL,
    updated_at DATE NOT NULL,
    content TEXT NOT NULL,
    tags TEXT,
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);

