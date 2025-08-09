-- Migration: create_post_images_table (UP)
-- Created: 2025-07-13 07:19:01

CREATE TABLE IF NOT EXISTS "PostImages" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    FOREIGN KEY (post_id) REFERENCES "Post"(id) ON DELETE CASCADE
);

