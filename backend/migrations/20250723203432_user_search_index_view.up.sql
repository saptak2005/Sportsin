-- Migration: user_search_index_view (UP)
-- Created: 2025-07-23 20:34:32


CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE MATERIALIZED VIEW user_search_index AS
SELECT
  u.id,
  u.username,
  u.email,
  ud.name,
  ud.middlename,
  ud.surname,
  ud.about,
  ud.is_premium,
  r.organization_name,
  p.interest,
  to_tsvector('english',
    coalesce(u.username, '') || ' ' ||
    coalesce(ud.name, '') || ' ' ||
    coalesce(ud.surname, '') || ' ' ||
    coalesce(ud.about, '') || ' ' ||
    coalesce(r.organization_name, '') || ' ' ||
    coalesce(p.interest, '')
  ) AS search_vector
FROM "User" u
LEFT JOIN "UserDetails" ud ON u.id = ud.id
LEFT JOIN "Recruiter" r ON u.id = r.id
LEFT JOIN "Player" p ON u.id = p.id;
