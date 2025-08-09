-- Migration: update_user_table (DOWN)
-- Created: 2025-07-29 01:18:47
ALTER TABLE "User" DROP COLUMN sns_endpoint_arn;
ALTER TABLE "User" DROP COLUMN device_token;