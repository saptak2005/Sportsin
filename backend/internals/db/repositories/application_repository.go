package repositories

import (
	"database/sql"
	"strings"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// Helper function to validate application status
func isValidApplicationStatus(status model.ApplicationStatus) bool {
	switch model.ApplicationStatus(status) {
	case model.ApplicationStatusPending, model.ApplicationStatusAccepted,
		model.ApplicationStatusRejected, model.ApplicationStatusWithdrawn:
		return true
	default:
		return false
	}
}

// CheckApplicationExists checks if an application exists for a given player and opening
func (r *Repository) CheckApplicationExists(playerID, openingID string) (bool, error) {
	// Validate input
	if strings.TrimSpace(playerID) == "" {
		return false, db.NewValidationError("player_id", "player ID cannot be empty")
	}
	if strings.TrimSpace(openingID) == "" {
		return false, db.NewValidationError("opening_id", "opening ID cannot be empty")
	}

	var exists bool
	err := r.DB.QueryRow(
		`SELECT EXISTS(SELECT 1 FROM "Application" WHERE player_id = $1 AND opening_id = $2)`,
		playerID, openingID,
	).Scan(&exists)

	if err != nil {
		return false, db.NewDatabaseError("check existence", "Application", err)
	}

	return exists, nil
}

func (r *Repository) CreateApplication(application *model.Application) (string, error) {
	// Validate input
	if application == nil {
		return "", db.NewValidationError("application", "application cannot be nil")
	}
	if strings.TrimSpace(application.PlayerID) == "" {
		return "", db.NewValidationError("player_id", "player ID cannot be empty")
	}
	if strings.TrimSpace(application.OpeningID) == "" {
		return "", db.NewValidationError("opening_id", "opening ID cannot be empty")
	}
	if application.Status == "" {
		application.Status = model.ApplicationStatusPending // Default status
	}

	// Validate status is a valid ApplicationStatus
	if !isValidApplicationStatus(application.Status) {
		return "", db.NewValidationError("status", "invalid application status")
	}

	// Check if application already exists for this player and opening
	exists, err := r.CheckApplicationExists(application.PlayerID, application.OpeningID)
	if err != nil {
		return "", err
	}
	if exists {
		return "", db.NewAlreadyExistsError("application", "player_id and opening_id combination", application.PlayerID+" + "+application.OpeningID)
	}

	tx, err := r.DB.Begin()
	if err != nil {
		return "", db.NewDatabaseError("begin transaction", "Application", err)
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		}
	}()

	var applicationID string
	err = tx.QueryRow(
		`INSERT INTO "Application" (player_id, opening_id, status) 
		 VALUES ($1, $2, $3) RETURNING id`,
		application.PlayerID, application.OpeningID, application.Status,
	).Scan(&applicationID)

	if err != nil {
		// Check for unique constraint violations or foreign key constraint errors
		if db.IsUniqueConstraintError(err, "player_id") || db.IsUniqueConstraintError(err, "opening_id") {
			return "", db.NewAlreadyExistsError("application", "player_id and opening_id combination", application.PlayerID+" + "+application.OpeningID)
		}
		return "", db.NewDatabaseError("insert", "Application", err)
	}

	err = tx.Commit()
	if err != nil {
		return "", db.NewDatabaseError("commit transaction", "Application", err)
	}

	return applicationID, nil
}

func (r *Repository) GetApplicationByID(applicationID string) (*model.Application, error) {
	// Validate input
	if strings.TrimSpace(applicationID) == "" {
		return nil, db.NewValidationError("application_id", "application ID cannot be empty")
	}

	var application model.Application

	err := r.DB.QueryRow(
		`SELECT id, player_id, opening_id, status, created_at, updated_at 
		 FROM "Application" WHERE id = $1`,
		applicationID,
	).Scan(
		&application.Id, &application.PlayerID, &application.OpeningID,
		&application.Status, &application.CreatedAt, &application.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("application", applicationID)
		}
		return nil, db.NewDatabaseError("select", "Application", err)
	}

	return &application, nil
}

func (r *Repository) GetApplicationByPlayerIDAndOpeningID(playerID, openingID string) (*model.Application, error) {
	playerID = strings.TrimSpace(playerID)
	applicationID := strings.TrimSpace(openingID)
	if playerID == "" || applicationID == "" {
		return nil, db.NewValidationError("player_id and application_id", "player ID and application ID cannot be empty")
	}

	var application model.Application
	err := r.DB.QueryRow(
		`SELECT id, player_id, opening_id, status, created_at, updated_at 
		 FROM "Application" WHERE player_id = $1 AND opening_id = $2`,
		playerID, applicationID,
	).Scan(
		&application.Id, &application.PlayerID, &application.OpeningID,
		&application.Status, &application.CreatedAt, &application.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("application", applicationID)
		}
		return nil, db.NewDatabaseError("select", "Application", err)
	}

	return &application, nil
}

func (r *Repository) GetApplicationsByPlayerID(playerID string) ([]*model.Application, error) {
	// Validate input
	if strings.TrimSpace(playerID) == "" {
		return nil, db.NewValidationError("player_id", "player ID cannot be empty")
	}

	rows, err := r.DB.Query(
		`SELECT id, player_id, opening_id, status, created_at, updated_at 
		 FROM "Application" WHERE player_id = $1`,
		playerID,
	)
	if err != nil {
		return nil, db.NewDatabaseError("select", "Application", err)
	}
	defer rows.Close()

	var applications []*model.Application
	for rows.Next() {
		var application model.Application
		if err := rows.Scan(
			&application.Id, &application.PlayerID, &application.OpeningID,
			&application.Status, &application.CreatedAt, &application.UpdatedAt,
		); err != nil {
			return nil, db.NewDatabaseError("scan row", "Application", err)
		}
		applications = append(applications, &application)
	}

	if err := rows.Err(); err != nil {
		return nil, db.NewDatabaseError("iterate rows", "Application", err)
	}

	return applications, nil
}

func (r *Repository) UpdateApplicationStatus(applicationID string, status model.ApplicationStatus) error {
	// Validate input
	if strings.TrimSpace(applicationID) == "" {
		return db.NewValidationError("application_id", "application ID cannot be empty")
	}

	// Validate status is a valid ApplicationStatus
	if !isValidApplicationStatus(status) {
		return db.NewValidationError("status", "invalid application status")
	}

	result, err := r.DB.Exec(
		`UPDATE "Application" SET status = $1, updated_at = NOW() 
		 WHERE id = $2`,
		status, applicationID,
	)

	if err != nil {
		return db.NewDatabaseError("update", "Application", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return db.NewDatabaseError("check rows affected", "Application", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("application", applicationID)
	}

	return nil
}

func (r *Repository) DeleteApplication(applicationID string) error {
	// Validate input
	if strings.TrimSpace(applicationID) == "" {
		return db.NewValidationError("application_id", "application ID cannot be empty")
	}

	result, err := r.DB.Exec(
		`DELETE FROM "Application" WHERE id = $1`,
		applicationID,
	)

	if err != nil {
		return db.NewDatabaseError("delete", "Application", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return db.NewDatabaseError("check rows affected", "Application", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("application", applicationID)
	}

	return nil
}

func (r *Repository) GetApplicationsByOpeningID(openingID string) ([]*model.Application, error) {
	// Validate input
	if strings.TrimSpace(openingID) == "" {
		return nil, db.NewValidationError("opening_id", "opening ID cannot be empty")
	}

	rows, err := r.DB.Query(
		`SELECT id, player_id, opening_id, status, created_at, updated_at 
		 FROM "Application" WHERE opening_id = $1`,
		openingID,
	)
	if err != nil {
		return nil, db.NewDatabaseError("select", "Application", err)
	}
	defer rows.Close()

	var applications []*model.Application
	for rows.Next() {
		var application model.Application
		if err := rows.Scan(
			&application.Id, &application.PlayerID, &application.OpeningID,
			&application.Status, &application.CreatedAt, &application.UpdatedAt,
		); err != nil {
			return nil, db.NewDatabaseError("scan row", "Application", err)
		}
		applications = append(applications, &application)
	}

	if err := rows.Err(); err != nil {
		return nil, db.NewDatabaseError("iterate rows", "Application", err)
	}

	return applications, nil
}

// GetApplicationsByStatus retrieves applications by status with optional pagination
func (r *Repository) GetApplicationsByStatus(status model.ApplicationStatus, limit, offset int) ([]*model.Application, error) {
	// Validate input
	if !isValidApplicationStatus(status) {
		return nil, db.NewValidationError("status", "invalid application status")
	}
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	rows, err := r.DB.Query(
		`SELECT id, player_id, opening_id, status, created_at, updated_at 
		 FROM "Application" WHERE status = $1 
		 ORDER BY created_at DESC 
		 LIMIT $2 OFFSET $3`,
		status, limit, offset,
	)
	if err != nil {
		return nil, db.NewDatabaseError("select", "Application", err)
	}
	defer rows.Close()

	var applications []*model.Application
	for rows.Next() {
		var application model.Application
		if err := rows.Scan(
			&application.Id, &application.PlayerID, &application.OpeningID,
			&application.Status, &application.CreatedAt, &application.UpdatedAt,
		); err != nil {
			return nil, db.NewDatabaseError("scan row", "Application", err)
		}
		applications = append(applications, &application)
	}

	if err := rows.Err(); err != nil {
		return nil, db.NewDatabaseError("iterate rows", "Application", err)
	}

	return applications, nil
}

func (r *Repository) GetApplicantsByOpeningID(openingID string) ([]*model.Applicant, error) {
	// Validate input
	if strings.TrimSpace(openingID) == "" {
		return nil, db.NewValidationError("opening_id", "opening ID cannot be empty")
	}

	rows, err := r.DB.Query(
		`SELECT p.id, p.level, p.interest, p.interest_country,
		        u.username, u.email, u.role, u.created_at, u.updated_at,
		        ud.profile_pic, ud.name, ud.middlename, 
		        ud.surname, ud.dob, ud.gender, ud.about, a.status
		 FROM "Player" p
		 INNER JOIN "Application" a ON p.id = a.player_id
		 INNER JOIN "User" u ON p.id = u.id
		 INNER JOIN "UserDetails" ud ON p.id = ud.id
		 WHERE a.opening_id = $1
		 ORDER BY a.created_at DESC`,
		openingID,
	)
	if err != nil {
		return nil, db.NewDatabaseError("select", "Player", err)
	}
	defer rows.Close()

	var applicants []*model.Applicant
	for rows.Next() {
		var applicant model.Applicant
		if err := rows.Scan(
			&applicant.Id, &applicant.Level, &applicant.InterestLevel, &applicant.InterestCountry,
			&applicant.Username, &applicant.Email, &applicant.Role, &applicant.CreatedAt, &applicant.UpdatedAt,
			&applicant.ProfilePicture, &applicant.Name, &applicant.MiddleName,
			&applicant.Surname, &applicant.DOB, &applicant.Gender, &applicant.About, &applicant.Status,
		); err != nil {
			return nil, db.NewDatabaseError("scan row", "Player", err)
		}
		applicant.OpeningID = openingID
		applicants = append(applicants, &applicant)
	}

	if err := rows.Err(); err != nil {
		return nil, db.NewDatabaseError("iterate rows", "Player", err)
	}

	return applicants, nil
}
