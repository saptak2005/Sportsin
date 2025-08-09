-- Migration: add_referal_coin_fields (UP)
-- Created: 2025-07-22 20:05:23

ALTER TABLE "UserDetails" ADD COLUMN IF NOT EXISTS referral_code VARCHAR(255);
ALTER TABLE "UserDetails" ADD COLUMN IF NOT EXISTS referred_by UUID;
ALTER TABLE "UserDetails" ADD COLUMN IF NOT EXISTS coins INT default 0;
ALTER TABLE "UserDetails" ADD CONSTRAINT "User_referral_code_unique" UNIQUE ("referral_code");
ALTER TABLE "UserDetails" ADD CONSTRAINT "referred_by_fkey" FOREIGN KEY ("referred_by") REFERENCES "UserDetails"("id") ON DELETE SET NULL ON UPDATE CASCADE;
