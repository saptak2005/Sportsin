-- Migration: post_like_count (UP)
-- Created: 2025-07-14 22:29:30

ALTER TABLE "Post" ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;