-- Migration: create_opening_table (UP)
-- Created: 2025-07-19 20:14:32

CREATE TABLE IF NOT EXISTS "Opening"(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sport_id UUID NOT NULL,
  recruiter_id UUID NOT NULL,
  company_name VARCHAR(100) NOT NULL,
  title VARCHAR(100) NOT NULL,
  description VARCHAR(255) NOT NULL,
  status VARCHAR(100) NOT NULL,
  position VARCHAR(100) NOT NULL,
  min_age INT,
  max_age INT,
  min_level VARCHAR(100),
  min_salary INT,
  max_salary INT,
  country_restriction VARCHAR(100),
  address_id UUID,
  stats JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE,
  FOREIGN KEY (recruiter_id) REFERENCES "Recruiter"(id) ON DELETE CASCADE,
  FOREIGN KEY (address_id) REFERENCES "SAddress"(id) ON DELETE CASCADE
  ); 
