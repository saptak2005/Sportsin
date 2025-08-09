package repositories

import (
	"database/sql"
	"encoding/json"
	"log"
	"strconv"
	"strings"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

func (r *Repository) CreateOpening(opening *model.Opening, saddress *model.SAddress, sportName string) (string, error) {
	tx, err := r.DB.Begin()
	if err != nil {
		return "", db.NewDatabaseError("begin", "transaction", err)
	}

	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
			if err != nil {
				err = db.NewDatabaseError("Failed to commit transaction", "transaction", err)
			}
		}
	}()

	sportName = strings.TrimSpace(sportName)
	if sportName == "" {
		return "", db.NewValidationError("sportname", "Sport name cannot be empty")
	}
	sportName = strings.ToLower(sportName)

	var sportID string
	var addressID string

	err = r.DB.QueryRow(`SELECT id FROM "Sports" WHERE name = $1`, sportName).Scan(&sportID)
	if err != nil {
		log.Println(err)
		if err == sql.ErrNoRows {
			err = tx.QueryRow(`INSERT INTO "Sports" (name) VALUES ($1) RETURNING id`, sportName).Scan(&sportID)
			if err != nil {
				return "", db.NewDatabaseError("insert", "sport", err)
			}
		} else {
			return "", db.NewDatabaseError("query", "sport", err)
		}
	}
	err = tx.QueryRow(`INSERT INTO "SAddress" (country, street, city, state, building, postal_code) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		saddress.Country, saddress.Street, saddress.City, saddress.State, saddress.Building, saddress.PostalCode).Scan(&addressID)
	if err != nil {
		return "", db.NewDatabaseError("insert", "saddress", err)
	}
	opening.SportID = sportID
	opening.AddressID = addressID

	var statsJSON any
	if opening.Stats != nil {
		var err error
		statsJSON, err = json.Marshal(opening.Stats)
		if err != nil {
			return "", db.NewDatabaseError("marshal", "stats", err)
		}
	} else {
		statsJSON = nil
	}

	err = tx.QueryRow(
		`INSERT INTO "Opening" (sport_id, recruiter_id, company_name, title, description, status, position, min_age, max_age, min_salary, max_salary, country_restriction, address_id, stats) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING id`,
		opening.SportID, opening.RecruiterID, opening.CompanyName, opening.Title, opening.Description, opening.Status, opening.Position, opening.MinAge, opening.MaxAge, opening.MinSalary, opening.MaxSalary, opening.CountryRestriction, opening.AddressID, statsJSON).Scan(&opening.Id)
	if err != nil {
		return "", db.NewDatabaseError("insert", "opening", err)
	}
	return opening.Id, nil
}

func (r *Repository) UpdateOpening(opening *model.OpeningDetails) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return db.NewDatabaseError("begin", "transaction", err)
	}

	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
			if err != nil {
				err = db.NewDatabaseError("Failed to commit transaction", "transaction", err)
			}
		}
	}()

	var sportsID string
	err = tx.QueryRow(`SELECT id FROM "Sports" WHERE name = $1`, opening.SportName).Scan(&sportsID)
	if err != nil {
		if err == sql.ErrNoRows {
			err = tx.QueryRow(`INSERT INTO "Sports" (name) VALUES ($1) RETURNING id`, opening.SportName).Scan(&sportsID)
			if err != nil {
				return db.NewDatabaseError("insert", "sport", err)
			}
		} else {
			return db.NewDatabaseError("query", "sport", err)
		}
	}

	opening.Opening.SportID = sportsID

	var statsJSON any
	if opening.Opening.Stats != nil {
		var err error
		statsJSON, err = json.Marshal(opening.Opening.Stats)
		if err != nil {
			return db.NewDatabaseError("marshal", "stats", err)
		}
	} else {
		statsJSON = nil
	}

	query := `UPDATE "Opening" SET sport_id = $1, recruiter_id = $2, company_name = $3, title = $4, description = $5, 
			  status = $6, position = $7, min_age = $8, max_age = $9, min_salary = $10, max_salary = $11, 
			  country_restriction = $12, address_id = $13, stats = $14 WHERE id = $15`
	_, err = tx.Exec(query,
		opening.Opening.SportID, opening.Opening.RecruiterID, opening.Opening.CompanyName,
		opening.Opening.Title, opening.Opening.Description, opening.Opening.Status,
		opening.Opening.Position, opening.Opening.MinAge, opening.Opening.MaxAge,
		opening.Opening.MinSalary, opening.Opening.MaxSalary,
		opening.Opening.CountryRestriction, opening.Opening.AddressID, statsJSON, opening.Opening.Id)

	if err != nil {
		return db.NewDatabaseError("update", "opening", err)
	}

	query = `UPDATE "SAddress" SET country = $1, state = $2, city = $3, street = $4, building = $5, postal_code = $6 WHERE id = $7`
	_, err = tx.Exec(query,
		opening.Address.Country, opening.Address.State, opening.Address.City,
		opening.Address.Street, opening.Address.Building, opening.Address.PostalCode,
		opening.Address.Id)

	if err != nil {
		return db.NewDatabaseError("update", "saddress", err)
	}

	return nil
}

func (r *Repository) DeleteOpening(openingID string) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return db.NewDatabaseError("begin", "transaction", err)
	}

	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
			if err != nil {
				err = db.NewDatabaseError("Failed to commit transaction", "transaction", err)
			}
		}
	}()

	query := `DELETE FROM "Opening" WHERE id = $1`
	_, err = tx.Exec(query, openingID)
	if err != nil {
		return db.NewDatabaseError("delete", "opening", err)
	}

	return nil
}

func (r *Repository) UpdateOpeningStatus(openingID string, status model.OpeningStatus) error {
	tx, err := r.DB.Begin()
	if err != nil {
		return db.NewDatabaseError("begin", "transaction", err)
	}

	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
			if err != nil {
				err = db.NewDatabaseError("Failed to commit transaction", "transaction", err)
			}
		}
	}()

	query := `UPDATE "Opening" SET status = $1 WHERE id = $2`
	_, err = tx.Exec(query, status, openingID)
	if err != nil {
		return db.NewDatabaseError("update", "opening status", err)
	}

	return nil
}

func (r *Repository) GetOpeningByID(openingID string, playerID *string) (*model.OpeningDetails, error) {
	var query string
	var args []any

	if playerID != nil {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					CASE WHEN app.id IS NOT NULL THEN true ELSE false END AS applied,
					app.status AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					LEFT JOIN "Application" app ON o.id = app.opening_id AND app.player_id = $2
					WHERE o.id = $1`
		args = []any{openingID, *playerID}
	} else {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					false AS applied,
					NULL AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					WHERE o.id = $1`
		args = []any{openingID}
	}

	row := r.DB.QueryRow(query, args...)
	openingDetails := &model.OpeningDetails{
		Opening: &model.Opening{},
		Address: &model.SAddress{},
	}

	var statsJSON sql.NullString
	var applied bool
	var applicationStatusStr sql.NullString
	err := row.Scan(
		&openingDetails.Opening.Id,
		&openingDetails.Opening.SportID,
		&openingDetails.Opening.RecruiterID,
		&openingDetails.Opening.CompanyName,
		&openingDetails.Opening.Title,
		&openingDetails.Opening.Description,
		&openingDetails.Opening.Status,
		&openingDetails.Opening.Position,
		&openingDetails.Opening.MinAge,
		&openingDetails.Opening.MaxAge,
		&openingDetails.Opening.MinLevel,
		&openingDetails.Opening.MinSalary,
		&openingDetails.Opening.MaxSalary,
		&openingDetails.Opening.CountryRestriction,
		&openingDetails.Opening.AddressID,
		&statsJSON,
		&openingDetails.SportName,
		&openingDetails.Address.Country,
		&openingDetails.Address.State,
		&openingDetails.Address.City,
		&openingDetails.Address.Street,
		&openingDetails.Address.Building,
		&openingDetails.Address.PostalCode,
		&applied,
		&applicationStatusStr,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("opening", openingID)
		}
		return nil, db.NewDatabaseError("query", "get opening by ID", err)
	}

	// Set application fields
	openingDetails.Applied = applied
	if applicationStatusStr.Valid {
		appStatus := model.ApplicationStatus(applicationStatusStr.String)
		openingDetails.ApplicationStatus = &appStatus
	}

	// Unmarshal the JSONB stats if present
	if statsJSON.Valid && len(statsJSON.String) > 0 {
		if err := json.Unmarshal([]byte(statsJSON.String), &openingDetails.Opening.Stats); err != nil {
			return nil, db.NewDatabaseError("unmarshal", "stats", err)
		}
	}

	return openingDetails, nil
}

func (r *Repository) GetOpeningsByRecruiterID(recruiterID string, limit, offset int, playerID *string) ([]*model.OpeningDetails, error) {
	var query string
	var args []any

	if playerID != nil {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					CASE WHEN app.id IS NOT NULL THEN true ELSE false END AS applied,
					app.status AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					LEFT JOIN "Application" app ON o.id = app.opening_id AND app.player_id = $4
					WHERE o.recruiter_id = $1
					ORDER BY o.created_at DESC
					LIMIT $2 OFFSET $3`
		args = []any{recruiterID, limit, offset, *playerID}
	} else {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					false AS applied,
					NULL AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					WHERE o.recruiter_id = $1
					ORDER BY o.created_at DESC
					LIMIT $2 OFFSET $3`
		args = []any{recruiterID, limit, offset}
	}

	rows, err := r.DB.Query(query, args...)
	if err != nil {
		return nil, db.NewDatabaseError("query", "get openings by recruiter ID", err)
	}
	defer rows.Close()

	var openings []*model.OpeningDetails
	for rows.Next() {
		openingDetails := &model.OpeningDetails{
			Opening: &model.Opening{},
			Address: &model.SAddress{},
		}

		var statsJSON sql.NullString
		var applied bool
		var applicationStatusStr sql.NullString
		err := rows.Scan(
			&openingDetails.Opening.Id,
			&openingDetails.Opening.SportID,
			&openingDetails.Opening.RecruiterID,
			&openingDetails.Opening.CompanyName,
			&openingDetails.Opening.Title,
			&openingDetails.Opening.Description,
			&openingDetails.Opening.Status,
			&openingDetails.Opening.Position,
			&openingDetails.Opening.MinAge,
			&openingDetails.Opening.MaxAge,
			&openingDetails.Opening.MinLevel,
			&openingDetails.Opening.MinSalary,
			&openingDetails.Opening.MaxSalary,
			&openingDetails.Opening.CountryRestriction,
			&openingDetails.Opening.AddressID,
			&statsJSON,
			&openingDetails.SportName,
			&openingDetails.Address.Country,
			&openingDetails.Address.State,
			&openingDetails.Address.City,
			&openingDetails.Address.Street,
			&openingDetails.Address.Building,
			&openingDetails.Address.PostalCode,
			&applied,
			&applicationStatusStr,
		)

		if err != nil {
			return nil, db.NewDatabaseError("scan", "get openings by recruiter ID", err)
		}

		// Set application fields
		openingDetails.Applied = applied
		if applicationStatusStr.Valid {
			appStatus := model.ApplicationStatus(applicationStatusStr.String)
			openingDetails.ApplicationStatus = &appStatus
		}

		// Unmarshal the JSONB stats if present
		if statsJSON.Valid && len(statsJSON.String) > 0 {
			if err := json.Unmarshal([]byte(statsJSON.String), &openingDetails.Opening.Stats); err != nil {
				return nil, db.NewDatabaseError("unmarshal", "stats", err)
			}
		}

		openings = append(openings, openingDetails)
	}

	if err = rows.Err(); err != nil {
		return nil, db.NewDatabaseError("rows", "get openings by recruiter ID", err)
	}
	return openings, nil
}

func (r *Repository) GetAllOpenings(limit, offset int, playerID *string) ([]*model.OpeningDetails, error) {
	var query string
	var args []any

	if playerID != nil {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					CASE WHEN app.id IS NOT NULL THEN true ELSE false END AS applied,
					app.status AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					LEFT JOIN "Application" app ON o.id = app.opening_id AND app.player_id = $3
					ORDER BY o.created_at DESC 
					LIMIT $1 OFFSET $2`
		args = []any{limit, offset, *playerID}
	} else {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					false AS applied,
					NULL AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					ORDER BY o.created_at DESC 
					LIMIT $1 OFFSET $2`
		args = []any{limit, offset}
	}

	rows, err := r.DB.Query(query, args...)
	if err != nil {
		return nil, db.NewDatabaseError("query", "get all openings", err)
	}
	defer rows.Close()

	var openings []*model.OpeningDetails
	for rows.Next() {
		openingDetails := &model.OpeningDetails{
			Opening: &model.Opening{},
			Address: &model.SAddress{},
		}

		var statsJSON sql.NullString
		var applied bool
		var applicationStatusStr sql.NullString
		err := rows.Scan(
			&openingDetails.Opening.Id,
			&openingDetails.Opening.SportID,
			&openingDetails.Opening.RecruiterID,
			&openingDetails.Opening.CompanyName,
			&openingDetails.Opening.Title,
			&openingDetails.Opening.Description,
			&openingDetails.Opening.Status,
			&openingDetails.Opening.Position,
			&openingDetails.Opening.MinAge,
			&openingDetails.Opening.MaxAge,
			&openingDetails.Opening.MinLevel,
			&openingDetails.Opening.MinSalary,
			&openingDetails.Opening.MaxSalary,
			&openingDetails.Opening.CountryRestriction,
			&openingDetails.Opening.AddressID,
			&statsJSON,
			&openingDetails.SportName,
			&openingDetails.Address.Country,
			&openingDetails.Address.State,
			&openingDetails.Address.City,
			&openingDetails.Address.Street,
			&openingDetails.Address.Building,
			&openingDetails.Address.PostalCode,
			&applied,
			&applicationStatusStr,
		)

		if err != nil {
			return nil, db.NewDatabaseError("scan", "get all openings", err)
		}

		// Set application fields
		openingDetails.Applied = applied
		if applicationStatusStr.Valid {
			appStatus := model.ApplicationStatus(applicationStatusStr.String)
			openingDetails.ApplicationStatus = &appStatus
		}

		// Unmarshal the JSONB stats if present
		if statsJSON.Valid && len(statsJSON.String) > 0 {
			if err := json.Unmarshal([]byte(statsJSON.String), &openingDetails.Opening.Stats); err != nil {
				return nil, db.NewDatabaseError("unmarshal", "stats", err)
			}
		}

		openings = append(openings, openingDetails)
	}

	if err = rows.Err(); err != nil {
		return nil, db.NewDatabaseError("rows", "get all openings", err)
	}
	return openings, nil
}

func (r *Repository) GetOpeningsBySport(sportName string, limit, offset int, playerID *string) ([]*model.OpeningDetails, error) {
	var query string
	var args []any

	if playerID != nil {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					CASE WHEN app.id IS NOT NULL THEN true ELSE false END AS applied,
					app.status AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					LEFT JOIN "Application" app ON o.id = app.opening_id AND app.player_id = $4
					WHERE s.name = $1
					ORDER BY o.created_at DESC
					LIMIT $2 OFFSET $3`
		args = []any{sportName, limit, offset, *playerID}
	} else {
		query = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					false AS applied,
					NULL AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id 
					WHERE s.name = $1
					ORDER BY o.created_at DESC
					LIMIT $2 OFFSET $3`
		args = []any{sportName, limit, offset}
	}

	rows, err := r.DB.Query(query, args...)
	if err != nil {
		return nil, db.NewDatabaseError("query", "get openings by sport", err)
	}
	defer rows.Close()

	var openings []*model.OpeningDetails
	for rows.Next() {
		openingDetails := &model.OpeningDetails{
			Opening: &model.Opening{},
			Address: &model.SAddress{},
		}

		var statsJSON sql.NullString
		var applied bool
		var applicationStatusStr sql.NullString
		err := rows.Scan(
			&openingDetails.Opening.Id,
			&openingDetails.Opening.SportID,
			&openingDetails.Opening.RecruiterID,
			&openingDetails.Opening.CompanyName,
			&openingDetails.Opening.Title,
			&openingDetails.Opening.Description,
			&openingDetails.Opening.Status,
			&openingDetails.Opening.Position,
			&openingDetails.Opening.MinAge,
			&openingDetails.Opening.MaxAge,
			&openingDetails.Opening.MinLevel,
			&openingDetails.Opening.MinSalary,
			&openingDetails.Opening.MaxSalary,
			&openingDetails.Opening.CountryRestriction,
			&openingDetails.Opening.AddressID,
			&statsJSON,
			&openingDetails.SportName,
			&openingDetails.Address.Country,
			&openingDetails.Address.State,
			&openingDetails.Address.City,
			&openingDetails.Address.Street,
			&openingDetails.Address.Building,
			&openingDetails.Address.PostalCode,
			&applied,
			&applicationStatusStr,
		)

		if err != nil {
			return nil, db.NewDatabaseError("scan", "get openings by sport", err)
		}

		// Set application fields
		openingDetails.Applied = applied
		if applicationStatusStr.Valid {
			appStatus := model.ApplicationStatus(applicationStatusStr.String)
			openingDetails.ApplicationStatus = &appStatus
		}

		// Unmarshal the JSONB stats if present
		if statsJSON.Valid && len(statsJSON.String) > 0 {
			if err := json.Unmarshal([]byte(statsJSON.String), &openingDetails.Opening.Stats); err != nil {
				return nil, db.NewDatabaseError("unmarshal", "stats", err)
			}
		}

		openings = append(openings, openingDetails)
	}

	if err = rows.Err(); err != nil {
		return nil, db.NewDatabaseError("rows", "get openings by sport", err)
	}
	return openings, nil
}

// OpeningFilter represents the filter criteria for searching openings
type OpeningFilter struct {
	SportName          *string              `json:"sport_name,omitempty"`
	Status             *model.OpeningStatus `json:"status,omitempty"`
	MinAge             *int                 `json:"min_age,omitempty"`
	MaxAge             *int                 `json:"max_age,omitempty"`
	MinSalary          *int                 `json:"min_salary,omitempty"`
	MaxSalary          *int                 `json:"max_salary,omitempty"`
	CountryRestriction *string              `json:"country_restriction,omitempty"`
	Country            *string              `json:"country,omitempty"`
	State              *string              `json:"state,omitempty"`
	City               *string              `json:"city,omitempty"`
	CompanyName        *string              `json:"company_name,omitempty"`
	Position           *string              `json:"position,omitempty"`
	Applied            *bool                `json:"applied,omitempty"`
}

func (r *Repository) GetOpeningsByFilter(filter *OpeningFilter, limit, offset int, playerID *string) ([]*model.OpeningDetails, error) {
	// If Applied filter is used but no playerID is provided, return error
	if filter.Applied != nil && playerID == nil {
		return nil, db.NewValidationError("authentication", "Authentication required to filter by applied status")
	}

	// Build the base query
	var baseQuery string
	if playerID != nil {
		baseQuery = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					CASE WHEN app.id IS NOT NULL THEN true ELSE false END AS applied,
					app.status AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id
					LEFT JOIN "Application" app ON o.id = app.opening_id AND app.player_id = $` + strconv.Itoa(1)
	} else {
		baseQuery = `SELECT o.id, o.sport_id, o.recruiter_id, o.company_name, o.title, o.description, o.status, 
					o.position, o.min_age, o.max_age, o.min_level, o.min_salary, o.max_salary, o.country_restriction, 
					o.address_id, o.stats, s.name AS sport_name, a.country, a.state, a.city, a.street, a.building, a.postal_code,
					false AS applied,
					NULL AS application_status
					FROM "Opening" o 
					JOIN "Sports" s ON o.sport_id = s.id 
					JOIN "SAddress" a ON o.address_id = a.id`
	}

	// Build WHERE conditions dynamically
	var conditions []string
	var args []any
	argIndex := 1

	// If playerID is provided, add it to args first
	if playerID != nil {
		args = append(args, *playerID)
		argIndex++
	}

	if filter.SportName != nil {
		conditions = append(conditions, "s.name = $"+strconv.Itoa(argIndex))
		args = append(args, *filter.SportName)
		argIndex++
	}

	if filter.Status != nil {
		conditions = append(conditions, "o.status = $"+strconv.Itoa(argIndex))
		args = append(args, *filter.Status)
		argIndex++
	}

	if filter.MinAge != nil {
		conditions = append(conditions, "(o.max_age IS NULL OR o.max_age >= $"+strconv.Itoa(argIndex)+")")
		args = append(args, *filter.MinAge)
		argIndex++
	}

	if filter.MaxAge != nil {
		conditions = append(conditions, "(o.min_age IS NULL OR o.min_age <= $"+strconv.Itoa(argIndex)+")")
		args = append(args, *filter.MaxAge)
		argIndex++
	}

	if filter.MinSalary != nil {
		conditions = append(conditions, "(o.max_salary IS NULL OR o.max_salary >= $"+strconv.Itoa(argIndex)+")")
		args = append(args, *filter.MinSalary)
		argIndex++
	}

	if filter.MaxSalary != nil {
		conditions = append(conditions, "(o.min_salary IS NULL OR o.min_salary <= $"+strconv.Itoa(argIndex)+")")
		args = append(args, *filter.MaxSalary)
		argIndex++
	}

	if filter.CountryRestriction != nil {
		conditions = append(conditions, "(o.country_restriction IS NULL OR o.country_restriction = $"+strconv.Itoa(argIndex)+")")
		args = append(args, *filter.CountryRestriction)
		argIndex++
	}

	if filter.Country != nil {
		conditions = append(conditions, "a.country ILIKE $"+strconv.Itoa(argIndex))
		args = append(args, "%"+*filter.Country+"%")
		argIndex++
	}

	if filter.State != nil {
		conditions = append(conditions, "a.state ILIKE $"+strconv.Itoa(argIndex))
		args = append(args, "%"+*filter.State+"%")
		argIndex++
	}

	if filter.City != nil {
		conditions = append(conditions, "a.city ILIKE $"+strconv.Itoa(argIndex))
		args = append(args, "%"+*filter.City+"%")
		argIndex++
	}

	if filter.CompanyName != nil {
		conditions = append(conditions, "o.company_name ILIKE $"+strconv.Itoa(argIndex))
		args = append(args, "%"+*filter.CompanyName+"%")
		argIndex++
	}

	if filter.Position != nil {
		conditions = append(conditions, "o.position ILIKE $"+strconv.Itoa(argIndex))
		args = append(args, "%"+*filter.Position+"%")
		argIndex++
	}

	if filter.Applied != nil {
		if *filter.Applied {
			// Only show openings that the user has applied to
			conditions = append(conditions, "app.id IS NOT NULL")
		} else {
			// Only show openings that the user has NOT applied to
			conditions = append(conditions, "app.id IS NULL")
		}
	}

	// Construct the final query
	query := baseQuery
	if len(conditions) > 0 {
		query += " WHERE " + strings.Join(conditions, " AND ")
	}
	query += " ORDER BY o.created_at DESC LIMIT $" + strconv.Itoa(argIndex) + " OFFSET $" + strconv.Itoa(argIndex+1)

	// Add limit and offset to args
	args = append(args, limit, offset)

	rows, err := r.DB.Query(query, args...)
	if err != nil {
		return nil, db.NewDatabaseError("query", "get openings by filter", err)
	}
	defer rows.Close()

	var openings []*model.OpeningDetails
	for rows.Next() {
		openingDetails := &model.OpeningDetails{
			Opening: &model.Opening{},
			Address: &model.SAddress{},
		}

		var statsJSON sql.NullString
		var applied bool
		var applicationStatusStr sql.NullString
		err := rows.Scan(
			&openingDetails.Opening.Id,
			&openingDetails.Opening.SportID,
			&openingDetails.Opening.RecruiterID,
			&openingDetails.Opening.CompanyName,
			&openingDetails.Opening.Title,
			&openingDetails.Opening.Description,
			&openingDetails.Opening.Status,
			&openingDetails.Opening.Position,
			&openingDetails.Opening.MinAge,
			&openingDetails.Opening.MaxAge,
			&openingDetails.Opening.MinLevel,
			&openingDetails.Opening.MinSalary,
			&openingDetails.Opening.MaxSalary,
			&openingDetails.Opening.CountryRestriction,
			&openingDetails.Opening.AddressID,
			&statsJSON,
			&openingDetails.SportName,
			&openingDetails.Address.Country,
			&openingDetails.Address.State,
			&openingDetails.Address.City,
			&openingDetails.Address.Street,
			&openingDetails.Address.Building,
			&openingDetails.Address.PostalCode,
			&applied,
			&applicationStatusStr,
		)

		if err != nil {
			return nil, db.NewDatabaseError("scan", "get openings by filter", err)
		}

		// Set application fields
		openingDetails.Applied = applied
		if applicationStatusStr.Valid {
			appStatus := model.ApplicationStatus(applicationStatusStr.String)
			openingDetails.ApplicationStatus = &appStatus
		}

		// Unmarshal the JSONB stats if present
		if statsJSON.Valid && len(statsJSON.String) > 0 {
			if err := json.Unmarshal([]byte(statsJSON.String), &openingDetails.Opening.Stats); err != nil {
				return nil, db.NewDatabaseError("unmarshal", "stats", err)
			}
		}

		openings = append(openings, openingDetails)
	}

	if err = rows.Err(); err != nil {
		return nil, db.NewDatabaseError("rows", "get openings by filter", err)
	}
	return openings, nil
}
