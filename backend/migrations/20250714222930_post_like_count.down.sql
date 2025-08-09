-- Migration: post_like_count (DOWN)
-- Created: 2025-07-14 22:29:30

ALTER TABLE "Post" DROP COLUMN like_count;