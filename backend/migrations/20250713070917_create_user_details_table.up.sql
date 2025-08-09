-- Migration: create_user_details_table (UP)
-- Created: 2025-07-13 07:09:17

CREATE TABLE IF NOT EXISTS "UserDetails"(
    id UUID PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    profile_pic VARCHAR(255),
    name VARCHAR(255),
    middlename VARCHAR(255),
    surname VARCHAR(255),
    dob DATE,
    gender VARCHAR(255),
    about TEXT,
    is_premium BOOLEAN DEFAULT false,
    FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
);

