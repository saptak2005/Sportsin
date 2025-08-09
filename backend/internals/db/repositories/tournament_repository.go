package repositories

import (
	"database/sql"
	"fmt"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// CreateTournament creates a new tournament
func (repo *Repository) CreateTournament(tournament *model.Tournament) error {
	query := `INSERT INTO "Tournament" (id, host_id, title, name, description, location, sport_id, min_age, max_age, level, level_location, gender, country_restriction, status, start_date, end_date, banner_link)
    VALUES (gen_random_uuid(), $1, $2, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	RETURNING id, created_at, updated_at`

	// Debug logging
	log.Printf("DEBUG: SQL Parameters:")
	log.Printf("  $1 (host_id): %s", tournament.HostId)
	log.Printf("  $2 (title): %s", tournament.Title)
	log.Printf("  $5 (sport_id): %s", tournament.SportId)

	err := repo.DB.QueryRow(query,
		tournament.HostId,      // $1
		tournament.Title,       // $2 (used for both title and name)
		tournament.Description, // $3
		tournament.Location,    // $4
		tournament.SportId,     // $5
		tournament.MinAge,      // $6
		tournament.MaxAge,      // $7
		tournament.Level,       // $8
		tournament.Location,    // $9 - Using location as level_location
		tournament.Gender,      // $10
		tournament.Country,     // $11
		tournament.Status,      // $12
		tournament.StartDate,   // $13
		tournament.EndDate,     // $14
		tournament.BannerUrl,   // $15
	).Scan(&tournament.Id, &tournament.CreatedAt, &tournament.UpdatedAt)

	if err != nil {
		log.Printf("ERROR: failed to create tournament: %v", err)
		return fmt.Errorf("CreateTournament: %w", err)
	}

	return nil
}

// GetTournamentByID retrieves a tournament by its ID (for internal operations)
func (repo *Repository) GetTournamentByID(tournamentID string) (*model.Tournament, error) {
	var tournament model.Tournament
	query := `SELECT id, host_id, title, description, location, sport_id, min_age, max_age, level, gender, country_restriction, status, banner_link, start_date, end_date, created_at, updated_at 
	FROM "Tournament" WHERE id = $1`

	err := repo.DB.QueryRow(query, tournamentID).Scan(
		&tournament.Id,
		&tournament.HostId,
		&tournament.Title,
		&tournament.Description,
		&tournament.Location,
		&tournament.SportId,
		&tournament.MinAge,
		&tournament.MaxAge,
		&tournament.Level,
		&tournament.Gender,
		&tournament.Country,
		&tournament.Status,
		&tournament.BannerUrl,
		&tournament.StartDate,
		&tournament.EndDate,
		&tournament.CreatedAt,
		&tournament.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.ITEM_NOT_FOUND
		}
		log.Printf("ERROR: failed to get tournament by ID: %v", err)
		return nil, fmt.Errorf("GetTournamentByID: %w", err)
	}

	return &tournament, nil
}

// GetTournamentDetailsByID retrieves tournament details by its ID with host name, sport details, and participants count
func (repo *Repository) GetTournamentDetailsByID(tournamentID string, userID *string) (*model.TournamentDetails, error) {
	query := `SELECT 
		t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at,
		ud.name as host_name,
		s.id as sport_id, s.name as sport_name, s.description as sport_description,
		s.created_at as sport_created_at, s.updated_at as sport_updated_at,
		COUNT(tp.id) as participants_count
	FROM "Tournament" t
	LEFT JOIN "UserDetails" ud ON t.host_id = ud.id
	LEFT JOIN "Sports" s ON t.sport_id = s.id
	LEFT JOIN "TournamentParticipant" tp ON t.id = tp.tournament_id AND tp.status = 'accepted'
	WHERE t.id = $1
	GROUP BY t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at, ud.name, ud.username, s.id, s.name, s.description, s.created_at, s.updated_at`

	var tournament model.Tournament
	var sport model.Sport
	var hostName string
	var participantsCount int

	err := repo.DB.QueryRow(query, tournamentID).Scan(
		&tournament.Id,
		&tournament.HostId,
		&tournament.Title,
		&tournament.Description,
		&tournament.Location,
		&tournament.SportId,
		&tournament.MinAge,
		&tournament.MaxAge,
		&tournament.Level,
		&tournament.Gender,
		&tournament.Country,
		&tournament.Status,
		&tournament.BannerUrl,
		&tournament.StartDate,
		&tournament.EndDate,
		&tournament.CreatedAt,
		&tournament.UpdatedAt,
		&hostName,
		&sport.Id,
		&sport.Name,
		&sport.Description,
		&sport.CreatedAt,
		&sport.UpdatedAt,
		&participantsCount,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.ITEM_NOT_FOUND
		}
		log.Printf("ERROR: failed to get tournament details by ID: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsByID: %w", err)
	}

	// Check if user is enrolled (if userID is provided)
	isEnrolled := false
	if userID != nil && *userID != "" {
		_, err := repo.GetParticipantByUserAndTournament(*userID, tournamentID)
		isEnrolled = (err == nil)
	}

	tournamentDetails := &model.TournamentDetails{
		Tournament:        &tournament,
		HostName:          hostName,
		Sport:             &sport,
		IsEnrolled:        isEnrolled,
		ParticipantsCount: participantsCount,
	}

	return tournamentDetails, nil
}

// GetAllTournamentDetails retrieves all tournament details with host name, sport details, and participants count
func (repo *Repository) GetAllTournamentDetails(userID *string) ([]*model.TournamentDetails, error) {
	query := `SELECT 
		t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at,
		COALESCE(ud.name, ud.username) as host_name,
		s.id as sport_id, s.name as sport_name, s.description as sport_description,
		s.created_at as sport_created_at, s.updated_at as sport_updated_at,
		COUNT(tp.id) as participants_count
	FROM "Tournament" t
	LEFT JOIN "UserDetails" ud ON t.host_id = ud.id
	LEFT JOIN "Sports" s ON t.sport_id = s.id
	LEFT JOIN "TournamentParticipant" tp ON t.id = tp.tournament_id AND tp.status = 'accepted'
	GROUP BY t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at, ud.name, ud.username, s.id, s.name, s.description, s.created_at, s.updated_at
	ORDER BY t.created_at DESC`

	rows, err := repo.DB.Query(query)
	if err != nil {
		log.Printf("ERROR: failed to get all tournament details: %v", err)
		return nil, fmt.Errorf("GetAllTournamentDetails: %w", err)
	}
	defer rows.Close()

	var tournamentDetailsList []*model.TournamentDetails
	for rows.Next() {
		var tournament model.Tournament
		var sport model.Sport
		var hostName string
		var participantsCount int

		err := rows.Scan(
			&tournament.Id,
			&tournament.HostId,
			&tournament.Title,
			&tournament.Description,
			&tournament.Location,
			&tournament.SportId,
			&tournament.MinAge,
			&tournament.MaxAge,
			&tournament.Level,
			&tournament.Gender,
			&tournament.Country,
			&tournament.Status,
			&tournament.BannerUrl,
			&tournament.StartDate,
			&tournament.EndDate,
			&tournament.CreatedAt,
			&tournament.UpdatedAt,
			&hostName,
			&sport.Id,
			&sport.Name,
			&sport.Description,
			&sport.CreatedAt,
			&sport.UpdatedAt,
			&participantsCount,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament details: %v", err)
			return nil, fmt.Errorf("GetAllTournamentDetails: %w", err)
		}

		// Check if user is enrolled (if userID is provided)
		isEnrolled := false
		if userID != nil && *userID != "" {
			_, err := repo.GetParticipantByUserAndTournament(*userID, tournament.Id)
			isEnrolled = (err == nil)
		}

		tournamentDetails := &model.TournamentDetails{
			Tournament:        &tournament,
			HostName:          hostName,
			Sport:             &sport,
			IsEnrolled:        isEnrolled,
			ParticipantsCount: participantsCount,
		}

		tournamentDetailsList = append(tournamentDetailsList, tournamentDetails)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetAllTournamentDetails: %w", err)
	}

	return tournamentDetailsList, nil
}

// GetTournamentDetailsByHostID retrieves tournament details by host ID with host name, sport details, and participants count
func (repo *Repository) GetTournamentDetailsByHostID(hostID string, userID *string) ([]*model.TournamentDetails, error) {
	query := `SELECT 
		t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at,
		COALESCE(ud.name, ud.username) as host_name,
		s.id as sport_id, s.name as sport_name, s.description as sport_description,
		s.created_at as sport_created_at, s.updated_at as sport_updated_at,
		COUNT(tp.id) as participants_count
	FROM "Tournament" t
	LEFT JOIN "UserDetails" ud ON t.host_id = ud.id
	LEFT JOIN "Sports" s ON t.sport_id = s.id
	LEFT JOIN "TournamentParticipant" tp ON t.id = tp.tournament_id AND tp.status = 'accepted'
	WHERE t.host_id = $1
	GROUP BY t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at, ud.name, ud.username, s.id, s.name, s.description, s.created_at, s.updated_at
	ORDER BY t.created_at DESC`

	rows, err := repo.DB.Query(query, hostID)
	if err != nil {
		log.Printf("ERROR: failed to get tournament details by host ID: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsByHostID: %w", err)
	}
	defer rows.Close()

	var tournamentDetailsList []*model.TournamentDetails
	for rows.Next() {
		var tournament model.Tournament
		var sport model.Sport
		var hostName string
		var participantsCount int

		err := rows.Scan(
			&tournament.Id,
			&tournament.HostId,
			&tournament.Title,
			&tournament.Description,
			&tournament.Location,
			&tournament.SportId,
			&tournament.MinAge,
			&tournament.MaxAge,
			&tournament.Level,
			&tournament.Gender,
			&tournament.Country,
			&tournament.Status,
			&tournament.BannerUrl,
			&tournament.StartDate,
			&tournament.EndDate,
			&tournament.CreatedAt,
			&tournament.UpdatedAt,
			&hostName,
			&sport.Id,
			&sport.Name,
			&sport.Description,
			&sport.CreatedAt,
			&sport.UpdatedAt,
			&participantsCount,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament details: %v", err)
			return nil, fmt.Errorf("GetTournamentDetailsByHostID: %w", err)
		}

		// Check if user is enrolled (if userID is provided)
		isEnrolled := false
		if userID != nil && *userID != "" {
			_, err := repo.GetParticipantByUserAndTournament(*userID, tournament.Id)
			isEnrolled = (err == nil)
		}

		tournamentDetails := &model.TournamentDetails{
			Tournament:        &tournament,
			HostName:          hostName,
			Sport:             &sport,
			IsEnrolled:        isEnrolled,
			ParticipantsCount: participantsCount,
		}

		tournamentDetailsList = append(tournamentDetailsList, tournamentDetails)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsByHostID: %w", err)
	}

	return tournamentDetailsList, nil
}

// GetTournamentDetailsBySportID retrieves tournament details by sport ID with host name, sport details, and participants count
func (repo *Repository) GetTournamentDetailsBySportID(sportID string, userID *string) ([]*model.TournamentDetails, error) {
	query := `SELECT 
		t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at,
		COALESCE(ud.name, ud.username) as host_name,
		s.id as sport_id, s.name as sport_name, s.description as sport_description,
		s.created_at as sport_created_at, s.updated_at as sport_updated_at,
		COUNT(tp.id) as participants_count
	FROM "Tournament" t
	LEFT JOIN "UserDetails" ud ON t.host_id = ud.id
	LEFT JOIN "Sports" s ON t.sport_id = s.id
	LEFT JOIN "TournamentParticipant" tp ON t.id = tp.tournament_id AND tp.status = 'accepted'
	WHERE t.sport_id = $1
	GROUP BY t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at, ud.name, ud.username, s.id, s.name, s.description, s.created_at, s.updated_at
	ORDER BY t.created_at DESC`

	rows, err := repo.DB.Query(query, sportID)
	if err != nil {
		log.Printf("ERROR: failed to get tournament details by sport ID: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsBySportID: %w", err)
	}
	defer rows.Close()

	var tournamentDetailsList []*model.TournamentDetails
	for rows.Next() {
		var tournament model.Tournament
		var sport model.Sport
		var hostName string
		var participantsCount int

		err := rows.Scan(
			&tournament.Id,
			&tournament.HostId,
			&tournament.Title,
			&tournament.Description,
			&tournament.Location,
			&tournament.SportId,
			&tournament.MinAge,
			&tournament.MaxAge,
			&tournament.Level,
			&tournament.Gender,
			&tournament.Country,
			&tournament.Status,
			&tournament.BannerUrl,
			&tournament.StartDate,
			&tournament.EndDate,
			&tournament.CreatedAt,
			&tournament.UpdatedAt,
			&hostName,
			&sport.Id,
			&sport.Name,
			&sport.Description,
			&sport.CreatedAt,
			&sport.UpdatedAt,
			&participantsCount,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament details: %v", err)
			return nil, fmt.Errorf("GetTournamentDetailsBySportID: %w", err)
		}

		// Check if user is enrolled (if userID is provided)
		isEnrolled := false
		if userID != nil && *userID != "" {
			_, err := repo.GetParticipantByUserAndTournament(*userID, tournament.Id)
			isEnrolled = (err == nil)
		}

		tournamentDetails := &model.TournamentDetails{
			Tournament:        &tournament,
			HostName:          hostName,
			Sport:             &sport,
			IsEnrolled:        isEnrolled,
			ParticipantsCount: participantsCount,
		}

		tournamentDetailsList = append(tournamentDetailsList, tournamentDetails)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsBySportID: %w", err)
	}

	return tournamentDetailsList, nil
}

// UpdateTournament updates an existing tournament
func (repo *Repository) UpdateTournament(tournament *model.Tournament) error {
	query := `UPDATE "Tournament" 
	SET name = $2, description = $3, location = $4, sport_id = $5, min_age = $6, max_age = $7, level = $8, level_location = $9, gender = $10, country_restriction = $11, status = $12, banner_link = $13, updated_at = CURRENT_TIMESTAMP
	WHERE id = $1`

	result, err := repo.DB.Exec(query,
		tournament.Id,
		tournament.Title,
		tournament.Description,
		tournament.Location,
		tournament.SportId,
		tournament.MinAge,
		tournament.MaxAge,
		tournament.Level,
		tournament.Location, // Using location as level_location for now
		tournament.Gender,
		tournament.Country,
		tournament.Status,
		tournament.BannerUrl,
	)

	if err != nil {
		log.Printf("ERROR: failed to update tournament: %v", err)
		return fmt.Errorf("UpdateTournament: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("UpdateTournament: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// DeleteTournament deletes a tournament by ID
func (repo *Repository) DeleteTournament(tournamentID string) error {
	query := `DELETE FROM "Tournament" WHERE id = $1`

	result, err := repo.DB.Exec(query, tournamentID)
	if err != nil {
		log.Printf("ERROR: failed to delete tournament: %v", err)
		return fmt.Errorf("DeleteTournament: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("DeleteTournament: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// GetTournamentDetailsByStatus retrieves tournament details by status with host name, sport details, and participants count
func (repo *Repository) GetTournamentDetailsByStatus(status model.TournamentStatus, userID *string) ([]*model.TournamentDetails, error) {
	query := `SELECT 
		t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at,
		COALESCE(ud.name, ud.username) as host_name,
		s.id as sport_id, s.name as sport_name, s.description as sport_description,
		s.created_at as sport_created_at, s.updated_at as sport_updated_at,
		COUNT(tp.id) as participants_count
	FROM "Tournament" t
	LEFT JOIN "UserDetails" ud ON t.host_id = ud.id
	LEFT JOIN "Sports" s ON t.sport_id = s.id
	LEFT JOIN "TournamentParticipant" tp ON t.id = tp.tournament_id AND tp.status = 'accepted'
	WHERE t.status = $1
	GROUP BY t.id, t.host_id, t.title, t.description, t.location, t.sport_id, t.min_age, t.max_age, 
		t.level, t.gender, t.country_restriction, t.status, t.banner_link, t.start_date, t.end_date, 
		t.created_at, t.updated_at, ud.name, ud.username, s.id, s.name, s.description, s.created_at, s.updated_at
	ORDER BY t.created_at DESC`

	rows, err := repo.DB.Query(query, status)
	if err != nil {
		log.Printf("ERROR: failed to get tournament details by status: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsByStatus: %w", err)
	}
	defer rows.Close()

	var tournamentDetailsList []*model.TournamentDetails
	for rows.Next() {
		var tournament model.Tournament
		var sport model.Sport
		var hostName string
		var participantsCount int

		err := rows.Scan(
			&tournament.Id,
			&tournament.HostId,
			&tournament.Title,
			&tournament.Description,
			&tournament.Location,
			&tournament.SportId,
			&tournament.MinAge,
			&tournament.MaxAge,
			&tournament.Level,
			&tournament.Gender,
			&tournament.Country,
			&tournament.Status,
			&tournament.BannerUrl,
			&tournament.StartDate,
			&tournament.EndDate,
			&tournament.CreatedAt,
			&tournament.UpdatedAt,
			&hostName,
			&sport.Id,
			&sport.Name,
			&sport.Description,
			&sport.CreatedAt,
			&sport.UpdatedAt,
			&participantsCount,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament details: %v", err)
			return nil, fmt.Errorf("GetTournamentDetailsByStatus: %w", err)
		}

		// Check if user is enrolled (if userID is provided)
		isEnrolled := false
		if userID != nil && *userID != "" {
			_, err := repo.GetParticipantByUserAndTournament(*userID, tournament.Id)
			isEnrolled = (err == nil)
		}

		tournamentDetails := &model.TournamentDetails{
			Tournament:        &tournament,
			HostName:          hostName,
			Sport:             &sport,
			IsEnrolled:        isEnrolled,
			ParticipantsCount: participantsCount,
		}

		tournamentDetailsList = append(tournamentDetailsList, tournamentDetails)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentDetailsByStatus: %w", err)
	}

	return tournamentDetailsList, nil
}
