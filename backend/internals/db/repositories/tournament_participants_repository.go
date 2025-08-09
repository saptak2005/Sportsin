package repositories

import (
	"database/sql"
	"fmt"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// AddTournamentParticipant adds a user as participant to a tournament
func (repo *Repository) AddTournamentParticipant(participant *model.TounramentParticipants) error {
	query := `INSERT INTO "TournamentParticipant" (id, user_id, tournament_id, status)
	VALUES (gen_random_uuid(), $1, $2, $3)
	RETURNING id, registered_at, registered_at`

	// Debug logging
	log.Printf("DEBUG: AddTournamentParticipant parameters:")
	log.Printf("  UserID: '%s'", participant.UserId)
	log.Printf("  TournamentID: '%s'", participant.TournamentId)
	log.Printf("  Status: '%s'", participant.Status)

	err := repo.DB.QueryRow(query,
		participant.UserId,
		participant.TournamentId,
		participant.Status,
	).Scan(&participant.Id, &participant.CreatedAt, &participant.UpdatedAt)

	if err != nil {
		log.Printf("ERROR: failed to add tournament participant: %v", err)
		return fmt.Errorf("AddTournamentParticipant: %w", err)
	}

	return nil
}

// GetTournamentParticipants retrieves all participants for a tournament
func (repo *Repository) GetTournamentParticipants(tournamentID string) ([]*model.TounramentParticipants, error) {
	query := `SELECT id, user_id, tournament_id, status, registered_at as created_at, registered_at as updated_at 
	FROM "TournamentParticipant" WHERE tournament_id = $1 ORDER BY registered_at DESC`

	rows, err := repo.DB.Query(query, tournamentID)
	if err != nil {
		log.Printf("ERROR: failed to get tournament participants: %v", err)
		return nil, fmt.Errorf("GetTournamentParticipants: %w", err)
	}
	defer rows.Close()

	var participants []*model.TounramentParticipants
	for rows.Next() {
		var participant model.TounramentParticipants
		err := rows.Scan(
			&participant.Id,
			&participant.UserId,
			&participant.TournamentId,
			&participant.Status,
			&participant.CreatedAt,
			&participant.UpdatedAt,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament participant: %v", err)
			return nil, fmt.Errorf("GetTournamentParticipants: %w", err)
		}
		participants = append(participants, &participant)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentParticipants: %w", err)
	}

	return participants, nil
}

// GetUserTournaments retrieves all tournaments a user is participating in
func (repo *Repository) GetUserTournaments(userID string) ([]*model.TounramentParticipants, error) {
	query := `SELECT id, user_id, tournament_id, status, registered_at as created_at, registered_at as updated_at 
	FROM "TournamentParticipant" WHERE user_id = $1 ORDER BY registered_at DESC`

	rows, err := repo.DB.Query(query, userID)
	if err != nil {
		log.Printf("ERROR: failed to get user tournaments: %v", err)
		return nil, fmt.Errorf("GetUserTournaments: %w", err)
	}
	defer rows.Close()

	var participants []*model.TounramentParticipants
	for rows.Next() {
		var participant model.TounramentParticipants
		err := rows.Scan(
			&participant.Id,
			&participant.UserId,
			&participant.TournamentId,
			&participant.Status,
			&participant.CreatedAt,
			&participant.UpdatedAt,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan user tournament: %v", err)
			return nil, fmt.Errorf("GetUserTournaments: %w", err)
		}
		participants = append(participants, &participant)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetUserTournaments: %w", err)
	}

	return participants, nil
}

// UpdateParticipantStatus updates the status of a tournament participant
func (repo *Repository) UpdateParticipantStatus(userID, tournamentID string, status model.ParticipationStatus) error {
	query := `UPDATE "TournamentParticipant" 
	SET status = $3 
	WHERE user_id = $1 AND tournament_id = $2`

	result, err := repo.DB.Exec(query, userID, tournamentID, status)
	if err != nil {
		log.Printf("ERROR: failed to update participant status: %v", err)
		return fmt.Errorf("UpdateParticipantStatus: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("UpdateParticipantStatus: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// RemoveTournamentParticipant removes a participant from a tournament
func (repo *Repository) RemoveTournamentParticipant(userID, tournamentID string) error {
	query := `DELETE FROM "TournamentParticipant" WHERE user_id = $1 AND tournament_id = $2`

	result, err := repo.DB.Exec(query, userID, tournamentID)
	if err != nil {
		log.Printf("ERROR: failed to remove tournament participant: %v", err)
		return fmt.Errorf("RemoveTournamentParticipant: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("RemoveTournamentParticipant: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// GetParticipantByUserAndTournament retrieves a specific participant record
func (repo *Repository) GetParticipantByUserAndTournament(userID, tournamentID string) (*model.TounramentParticipants, error) {
	var participant model.TounramentParticipants
	query := `SELECT id, user_id, tournament_id, status, registered_at as created_at, registered_at as updated_at 
	FROM "TournamentParticipant" WHERE user_id = $1 AND tournament_id = $2`

	err := repo.DB.QueryRow(query, userID, tournamentID).Scan(
		&participant.Id,
		&participant.UserId,
		&participant.TournamentId,
		&participant.Status,
		&participant.CreatedAt,
		&participant.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.ITEM_NOT_FOUND
		}
		log.Printf("ERROR: failed to get participant by user and tournament: %v", err)
		return nil, fmt.Errorf("GetParticipantByUserAndTournament: %w", err)
	}

	return &participant, nil
}

// GetTournamentParticipantsByStatus retrieves participants by status for a tournament
func (repo *Repository) GetTournamentParticipantsByStatus(tournamentID string, status model.ParticipationStatus) ([]*model.TounramentParticipants, error) {
	query := `SELECT id, user_id, tournament_id, status, registered_at as created_at, registered_at as updated_at 
	FROM "TournamentParticipant" WHERE tournament_id = $1 AND status = $2 ORDER BY registered_at DESC`

	rows, err := repo.DB.Query(query, tournamentID, status)
	if err != nil {
		log.Printf("ERROR: failed to get tournament participants by status: %v", err)
		return nil, fmt.Errorf("GetTournamentParticipantsByStatus: %w", err)
	}
	defer rows.Close()

	var participants []*model.TounramentParticipants
	for rows.Next() {
		var participant model.TounramentParticipants
		err := rows.Scan(
			&participant.Id,
			&participant.UserId,
			&participant.TournamentId,
			&participant.Status,
			&participant.CreatedAt,
			&participant.UpdatedAt,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament participant: %v", err)
			return nil, fmt.Errorf("GetTournamentParticipantsByStatus: %w", err)
		}
		participants = append(participants, &participant)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentParticipantsByStatus: %w", err)
	}

	return participants, nil
}
