package repositories

import (
	"database/sql"
	"strings"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// CreateSAddress creates a new SAddress record
func (r *Repository) CreateSAddress(saddress *model.SAddress) (string, error) {
	// Validate input
	if saddress == nil {
		return "", db.NewValidationError("saddress", "saddress cannot be nil")
	}
	if strings.TrimSpace(saddress.Country) == "" {
		return "", db.NewValidationError("country", "country cannot be empty")
	}
	if strings.TrimSpace(saddress.State) == "" {
		return "", db.NewValidationError("state", "state cannot be empty")
	}
	if strings.TrimSpace(saddress.City) == "" {
		return "", db.NewValidationError("city", "city cannot be empty")
	}
	if strings.TrimSpace(saddress.Street) == "" {
		return "", db.NewValidationError("street", "street cannot be empty")
	}
	if strings.TrimSpace(saddress.Building) == "" {
		return "", db.NewValidationError("building", "building cannot be empty")
	}
	if strings.TrimSpace(saddress.PostalCode) == "" {
		return "", db.NewValidationError("postal_code", "postal code cannot be empty")
	}

	tx, err := r.DB.Begin()
	if err != nil {
		return "", db.NewDatabaseError("begin transaction", "SAddress", err)
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		}
	}()

	var addressID string
	err = tx.QueryRow(
		`INSERT INTO "SAddress" (country, state, city, street, building, postal_code) 
		 VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
		saddress.Country, saddress.State, saddress.City,
		saddress.Street, saddress.Building, saddress.PostalCode,
	).Scan(&addressID)

	if err != nil {
		return "", db.NewDatabaseError("insert", "SAddress", err)
	}

	err = tx.Commit()
	if err != nil {
		return "", db.NewDatabaseError("commit transaction", "SAddress", err)
	}

	return addressID, nil
}

// GetSAddressByID retrieves an SAddress by its ID
func (r *Repository) GetSAddressByID(addressID string) (*model.SAddress, error) {
	// Validate input
	if strings.TrimSpace(addressID) == "" {
		return nil, db.NewValidationError("address_id", "address ID cannot be empty")
	}

	var saddress model.SAddress

	err := r.DB.QueryRow(
		`SELECT id, country, state, city, street, building, postal_code, created_at, updated_at 
		 FROM "SAddress" WHERE id = $1`,
		addressID,
	).Scan(
		&saddress.Id, &saddress.Country, &saddress.State, &saddress.City,
		&saddress.Street, &saddress.Building, &saddress.PostalCode,
		&saddress.CreatedAt, &saddress.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("saddress", addressID)
		}
		return nil, db.NewDatabaseError("select", "SAddress", err)
	}

	return &saddress, nil
}

// UpdateSAddress updates an existing SAddress record
func (r *Repository) UpdateSAddress(saddress *model.SAddress) error {
	// Validate input
	if saddress == nil {
		return db.NewValidationError("saddress", "saddress cannot be nil")
	}
	if strings.TrimSpace(saddress.Id) == "" {
		return db.NewValidationError("id", "address ID cannot be empty")
	}
	if strings.TrimSpace(saddress.Country) == "" {
		return db.NewValidationError("country", "country cannot be empty")
	}
	if strings.TrimSpace(saddress.State) == "" {
		return db.NewValidationError("state", "state cannot be empty")
	}
	if strings.TrimSpace(saddress.City) == "" {
		return db.NewValidationError("city", "city cannot be empty")
	}
	if strings.TrimSpace(saddress.Street) == "" {
		return db.NewValidationError("street", "street cannot be empty")
	}
	if strings.TrimSpace(saddress.Building) == "" {
		return db.NewValidationError("building", "building cannot be empty")
	}
	if strings.TrimSpace(saddress.PostalCode) == "" {
		return db.NewValidationError("postal_code", "postal code cannot be empty")
	}

	tx, err := r.DB.Begin()
	if err != nil {
		return db.NewDatabaseError("begin transaction", "SAddress", err)
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		}
	}()

	result, err := tx.Exec(
		`UPDATE "SAddress" 
		 SET country = $1, state = $2, city = $3, street = $4, building = $5, postal_code = $6, updated_at = CURRENT_TIMESTAMP
		 WHERE id = $7`,
		saddress.Country, saddress.State, saddress.City,
		saddress.Street, saddress.Building, saddress.PostalCode,
		saddress.Id,
	)

	if err != nil {
		return db.NewDatabaseError("update", "SAddress", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return db.NewDatabaseError("check rows affected", "SAddress", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("saddress", saddress.Id)
	}

	err = tx.Commit()
	if err != nil {
		return db.NewDatabaseError("commit transaction", "SAddress", err)
	}

	return nil
}

// DeleteSAddress deletes an SAddress by its ID
func (r *Repository) DeleteSAddress(addressID string) error {
	// Validate input
	if strings.TrimSpace(addressID) == "" {
		return db.NewValidationError("address_id", "address ID cannot be empty")
	}

	tx, err := r.DB.Begin()
	if err != nil {
		return db.NewDatabaseError("begin transaction", "SAddress", err)
	}
	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		} else if err != nil {
			tx.Rollback()
		}
	}()

	result, err := tx.Exec("DELETE FROM \"SAddress\" WHERE id = $1", addressID)
	if err != nil {
		return db.NewDatabaseError("delete", "SAddress", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return db.NewDatabaseError("check rows affected", "SAddress", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("saddress", addressID)
	}

	err = tx.Commit()
	if err != nil {
		return db.NewDatabaseError("commit transaction", "SAddress", err)
	}

	return nil
}

// ListSAddresses retrieves a paginated list of SAddresses
func (r *Repository) ListSAddresses(limit, offset int) ([]*model.SAddress, error) {
	// Validate input
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	rows, err := r.DB.Query(
		`SELECT id, country, state, city, street, building, postal_code, created_at, updated_at 
		 FROM "SAddress" 
		 ORDER BY created_at DESC 
		 LIMIT $1 OFFSET $2`,
		limit, offset,
	)
	if err != nil {
		return nil, db.NewDatabaseError("select", "SAddress", err)
	}
	defer rows.Close()

	var saddresses []*model.SAddress
	for rows.Next() {
		var saddress model.SAddress
		if err := rows.Scan(
			&saddress.Id, &saddress.Country, &saddress.State, &saddress.City,
			&saddress.Street, &saddress.Building, &saddress.PostalCode,
			&saddress.CreatedAt, &saddress.UpdatedAt,
		); err != nil {
			return nil, db.NewDatabaseError("scan row", "SAddress", err)
		}
		saddresses = append(saddresses, &saddress)
	}

	if err := rows.Err(); err != nil {
		return nil, db.NewDatabaseError("iterate rows", "SAddress", err)
	}

	return saddresses, nil
}
