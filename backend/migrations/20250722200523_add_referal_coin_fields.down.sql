-- Migration: add_referal_coin_fields (DOWN)
-- Created: 2025-07-22 20:05:23

-- Add your rollback SQL here
-- Example:
-- DROP TABLE IF EXISTS example;

ALTER TABLE "UserDetails" DROP COLUMN IF EXISTS referral_code;
ALTER TABLE "UserDetails" DROP COLUMN IF EXISTS referred_by;
ALTER TABLE "UserDetails" DROP COLUMN IF EXISTS coins;
ALTER TABLE "UserDetails" DROP CONSTRAINT IF EXISTS "User_referral_code_unique";
ALTER TABLE "UserDetails" DROP CONSTRAINT IF EXISTS "referred_by_fkey";

