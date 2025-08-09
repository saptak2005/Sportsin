-- Migration: create_recruiter_table (UP)
-- Created: 2025-07-13 07:15:33

CREATE TABLE IF NOT EXISTS "Recruiter" (
    id UUID PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    organization_id VARCHAR(100) NOT NULL,
    phone_no VARCHAR(20) NOT NULL,
    position VARCHAR(255),
    FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
);

