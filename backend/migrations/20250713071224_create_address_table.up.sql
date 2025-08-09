-- Migration: create_address_table (UP)
-- Created: 2025-07-13 07:12:24

CREATE TABLE IF NOT EXISTS "Address"(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    country VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    street VARCHAR(255) NOT NULL,
    building VARCHAR(100) NOT NULL,
    pincode VARCHAR(20) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
);

