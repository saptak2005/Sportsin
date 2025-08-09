-- Migration: update_user_table (UP)
-- Created: 2025-07-29 01:18:47

ALTER TABLE "User" ADD COLUMN sns_endpoint_arn VARCHAR(512);
ALTER TABLE "User" ADD COLUMN device_token VARCHAR(512);
