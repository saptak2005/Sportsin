package repositories

import (
	"database/sql"
	"fmt"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// CreateRecruiter creates a new recruiter profile
func (repo *Repository) CreateRecruiter(recruiter *model.Recruiter) error {
	query := `INSERT INTO "Recruiter" (id, organization_name, organization_id, phone_no, position)
	VALUES ($1, $2, $3, $4, $5)`

	_, err := repo.DB.Exec(query,
		recruiter.Id,
		recruiter.OrganizationName,
		recruiter.OrganizationId,
		recruiter.PhoneNumber,
		recruiter.Position,
	)

	if err != nil {
		log.Printf("ERROR: failed to create recruiter: %v", err)
		return fmt.Errorf("CreateRecruiter: %w", err)
	}

	return nil
}

// GetRecruiterByID retrieves a recruiter by user ID with full user details
func (repo *Repository) GetRecruiterByID(userID string) (*model.Recruiter, error) {
	var recruiter model.Recruiter
	query := `SELECT 
		u.id, u.username, u.email, u.role, u.created_at, u.updated_at,
		ud.user_name, ud.profile_picture, ud.name, ud.middle_name, ud.surname, ud.dob, ud.gender, ud.about,
		r.organization_name, r.organization_id, r.phone_no, r.position
	FROM "User" u
	LEFT JOIN "UserDetails" ud ON u.id = ud.id
	LEFT JOIN "Recruiter" r ON u.id = r.id
	WHERE u.id = $1 AND u.role = 'recruiter'`

	err := repo.DB.QueryRow(query, userID).Scan(
		&recruiter.Id,
		&recruiter.Username,
		&recruiter.Email,
		&recruiter.Role,
		&recruiter.CreatedAt,
		&recruiter.UpdatedAt,
		&recruiter.UserName,
		&recruiter.ProfilePicture,
		&recruiter.Name,
		&recruiter.MiddleName,
		&recruiter.Surname,
		&recruiter.DOB,
		&recruiter.Gender,
		&recruiter.About,
		&recruiter.OrganizationName,
		&recruiter.OrganizationId,
		&recruiter.PhoneNumber,
		&recruiter.Position,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.ITEM_NOT_FOUND
		}
		log.Printf("ERROR: failed to get recruiter by ID: %v", err)
		return nil, fmt.Errorf("GetRecruiterByID: %w", err)
	}

	return &recruiter, nil
}

// GetAllRecruiters retrieves all recruiters with pagination
func (repo *Repository) GetAllRecruiters(limit, offset int) ([]*model.Recruiter, error) {
	query := `SELECT 
		u.id, u.username, u.email, u.role, u.created_at, u.updated_at,
		ud.user_name, ud.profile_picture, ud.name, ud.middle_name, ud.surname, ud.dob, ud.gender, ud.about,
		r.organization_name, r.organization_id, r.phone_no, r.position
	FROM "User" u
	LEFT JOIN "UserDetails" ud ON u.id = ud.id
	LEFT JOIN "Recruiter" r ON u.id = r.id
	WHERE u.role = 'recruiter'
	ORDER BY u.created_at DESC
	LIMIT $1 OFFSET $2`

	rows, err := repo.DB.Query(query, limit, offset)
	if err != nil {
		log.Printf("ERROR: failed to get all recruiters: %v", err)
		return nil, fmt.Errorf("GetAllRecruiters: %w", err)
	}
	defer rows.Close()

	var recruiters []*model.Recruiter
	for rows.Next() {
		var recruiter model.Recruiter
		err := rows.Scan(
			&recruiter.Id,
			&recruiter.Username,
			&recruiter.Email,
			&recruiter.Role,
			&recruiter.CreatedAt,
			&recruiter.UpdatedAt,
			&recruiter.UserName,
			&recruiter.ProfilePicture,
			&recruiter.Name,
			&recruiter.MiddleName,
			&recruiter.Surname,
			&recruiter.DOB,
			&recruiter.Gender,
			&recruiter.About,
			&recruiter.OrganizationName,
			&recruiter.OrganizationId,
			&recruiter.PhoneNumber,
			&recruiter.Position,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan recruiter: %v", err)
			return nil, fmt.Errorf("GetAllRecruiters: %w", err)
		}
		recruiters = append(recruiters, &recruiter)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetAllRecruiters: %w", err)
	}

	return recruiters, nil
}

// GetRecruitersByOrganization retrieves recruiters by organization name
func (repo *Repository) GetRecruitersByOrganization(organizationName string) ([]*model.Recruiter, error) {
	query := `SELECT 
		u.id, u.username, u.email, u.role, u.created_at, u.updated_at,
		ud.user_name, ud.profile_picture, ud.name, ud.middle_name, ud.surname, ud.dob, ud.gender, ud.about,
		r.organization_name, r.organization_id, r.phone_no, r.position
	FROM "User" u
	LEFT JOIN "UserDetails" ud ON u.id = ud.id
	LEFT JOIN "Recruiter" r ON u.id = r.id
	WHERE u.role = 'recruiter' AND LOWER(r.organization_name) LIKE LOWER($1)
	ORDER BY u.created_at DESC`

	rows, err := repo.DB.Query(query, "%"+organizationName+"%")
	if err != nil {
		log.Printf("ERROR: failed to get recruiters by organization: %v", err)
		return nil, fmt.Errorf("GetRecruitersByOrganization: %w", err)
	}
	defer rows.Close()

	var recruiters []*model.Recruiter
	for rows.Next() {
		var recruiter model.Recruiter
		err := rows.Scan(
			&recruiter.Id,
			&recruiter.Username,
			&recruiter.Email,
			&recruiter.Role,
			&recruiter.CreatedAt,
			&recruiter.UpdatedAt,
			&recruiter.UserName,
			&recruiter.ProfilePicture,
			&recruiter.Name,
			&recruiter.MiddleName,
			&recruiter.Surname,
			&recruiter.DOB,
			&recruiter.Gender,
			&recruiter.About,
			&recruiter.OrganizationName,
			&recruiter.OrganizationId,
			&recruiter.PhoneNumber,
			&recruiter.Position,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan recruiter: %v", err)
			return nil, fmt.Errorf("GetRecruitersByOrganization: %w", err)
		}
		recruiters = append(recruiters, &recruiter)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetRecruitersByOrganization: %w", err)
	}

	return recruiters, nil
}

// UpdateRecruiter updates recruiter-specific information
func (repo *Repository) UpdateRecruiter(userID string, organizationName, organizationId, phoneNumber, position string) error {
	query := `UPDATE "Recruiter" 
	SET organization_name = $2, organization_id = $3, phone_no = $4, position = $5
	WHERE id = $1`

	result, err := repo.DB.Exec(query, userID, organizationName, organizationId, phoneNumber, position)
	if err != nil {
		log.Printf("ERROR: failed to update recruiter: %v", err)
		return fmt.Errorf("UpdateRecruiter: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("UpdateRecruiter: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// DeleteRecruiter deletes a recruiter profile (only recruiter-specific data)
func (repo *Repository) DeleteRecruiter(userID string) error {
	query := `DELETE FROM "Recruiter" WHERE id = $1`

	result, err := repo.DB.Exec(query, userID)
	if err != nil {
		log.Printf("ERROR: failed to delete recruiter: %v", err)
		return fmt.Errorf("DeleteRecruiter: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("DeleteRecruiter: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// SearchRecruiters searches recruiters by name, organization, or position
func (repo *Repository) SearchRecruiters(searchTerm string, limit, offset int) ([]*model.Recruiter, error) {
	query := `SELECT 
		u.id, u.username, u.email, u.role, u.created_at, u.updated_at,
		ud.user_name, ud.profile_picture, ud.name, ud.middle_name, ud.surname, ud.dob, ud.gender, ud.about,
		r.organization_name, r.organization_id, r.phone_no, r.position
	FROM "User" u
	LEFT JOIN "UserDetails" ud ON u.id = ud.id
	LEFT JOIN "Recruiter" r ON u.id = r.id
	WHERE u.role = 'recruiter' AND (
		LOWER(ud.name) LIKE LOWER($1) OR 
		LOWER(ud.surname) LIKE LOWER($1) OR
		LOWER(r.organization_name) LIKE LOWER($1) OR
		LOWER(r.position) LIKE LOWER($1)
	)
	ORDER BY u.created_at DESC
	LIMIT $2 OFFSET $3`

	rows, err := repo.DB.Query(query, "%"+searchTerm+"%", limit, offset)
	if err != nil {
		log.Printf("ERROR: failed to search recruiters: %v", err)
		return nil, fmt.Errorf("SearchRecruiters: %w", err)
	}
	defer rows.Close()

	var recruiters []*model.Recruiter
	for rows.Next() {
		var recruiter model.Recruiter
		err := rows.Scan(
			&recruiter.Id,
			&recruiter.Username,
			&recruiter.Email,
			&recruiter.Role,
			&recruiter.CreatedAt,
			&recruiter.UpdatedAt,
			&recruiter.UserName,
			&recruiter.ProfilePicture,
			&recruiter.Name,
			&recruiter.MiddleName,
			&recruiter.Surname,
			&recruiter.DOB,
			&recruiter.Gender,
			&recruiter.About,
			&recruiter.OrganizationName,
			&recruiter.OrganizationId,
			&recruiter.PhoneNumber,
			&recruiter.Position,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan recruiter: %v", err)
			return nil, fmt.Errorf("SearchRecruiters: %w", err)
		}
		recruiters = append(recruiters, &recruiter)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("SearchRecruiters: %w", err)
	}

	return recruiters, nil
}

// GetRecruiterCount returns the total number of recruiters
func (repo *Repository) GetRecruiterCount() (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM "User" WHERE role = 'recruiter'`

	err := repo.DB.QueryRow(query).Scan(&count)
	if err != nil {
		log.Printf("ERROR: failed to get recruiter count: %v", err)
		return 0, fmt.Errorf("GetRecruiterCount: %w", err)
	}

	return count, nil
}
