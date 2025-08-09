package repositories

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"

	"sportsin_backend/internals/model"
)

// CreateAchievement inserts a new achievement and returns the generated ID
func (repo *Repository) CreateAchievement(userId string, achievement *model.Achievement) error {
	query := `
		INSERT INTO "Achievements" 
		(id, user_id, date, sport_id, tournament_title, description, level, stats, certificate_link)
		VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, date
	`

	statsJSON, err := json.Marshal(achievement.Stats)
	if err != nil {
		log.Printf("Error marshaling stats: %v", err)
		return fmt.Errorf("invalid stats format: %w", err)
	}

	err = repo.DB.QueryRow(query,
		userId,
		achievement.Date,
		achievement.SportId,
		achievement.Tournament,
		achievement.Description,
		achievement.Level,
		statsJSON,
		achievement.CertificateUrl,
	).Scan(&achievement.Id, &achievement.Date)

	if err != nil {
		log.Printf("Error creating achievement: %v", err)
		return fmt.Errorf("failed to create achievement: %w", err)
	}

	return nil
}

// GetAchievementById fetches an achievement by its UUID
func (repo *Repository) GetAchievementById(id string) (*model.Achievement, error) {
	var achievement model.Achievement
	var statsJSON []byte

	query := `
		SELECT id, user_id, date, sport_id, tournament_title, description, level, stats, certificate_link
		FROM "Achievements" WHERE id = $1
	`

	err := repo.DB.QueryRow(query, id).Scan(
		&achievement.Id,
		&achievement.UserId,
		&achievement.Date,
		&achievement.SportId,
		&achievement.Tournament,
		&achievement.Description,
		&achievement.Level,
		&statsJSON,
		&achievement.CertificateUrl,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("achievement not found")
		}
		log.Printf("Error fetching achievement: %v", err)
		return nil, fmt.Errorf("failed to get achievement: %w", err)
	}

	_ = json.Unmarshal(statsJSON, &achievement.Stats)
	return &achievement, nil
}

// GetAchievementsByUser returns a paginated list of achievements for a user
func (repo *Repository) GetAchievementsByUser(userId string, limit, offset int) ([]model.Achievement, error) {
	query := `
		SELECT id, user_id, date, sport_id, tournament_title, description, level, stats, certificate_link
		FROM "Achievements"
		WHERE user_id = $1
		ORDER BY date DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := repo.DB.Query(query, userId, limit, offset)
	if err != nil {
		log.Printf("Error querying achievements: %v", err)
		return nil, fmt.Errorf("failed to get achievements: %w", err)
	}
	defer rows.Close()

	var achievements []model.Achievement

	for rows.Next() {
		var ach model.Achievement
		var statsJSON []byte

		err := rows.Scan(
			&ach.Id,
			&ach.UserId,
			&ach.Date,
			&ach.SportId,
			&ach.Tournament,
			&ach.Description,
			&ach.Level,
			&statsJSON,
			&ach.CertificateUrl,
		)

		if err != nil {
			log.Printf("Error scanning achievement: %v", err)
			continue
		}

		_ = json.Unmarshal(statsJSON, &ach.Stats)
		achievements = append(achievements, ach)
	}

	return achievements, nil
}

// GetAchievementsByUserId fetches all achievements for a user (no pagination)
func (repo *Repository) GetAchievementsByUserId(userId string) ([]model.Achievement, error) {
	query := `
		SELECT id, user_id, date, sport_id, tournament_title, description, level, stats, certificate_link
		FROM "Achievements"
		WHERE user_id = $1
		ORDER BY date DESC
	`

	rows, err := repo.DB.Query(query, userId)
	if err != nil {
		log.Printf("Error querying achievements: %v", err)
		return nil, fmt.Errorf("failed to get achievements: %w", err)
	}
	defer rows.Close()

	var achievements []model.Achievement

	for rows.Next() {
		var ach model.Achievement
		var statsJSON []byte

		err := rows.Scan(
			&ach.Id,
			&ach.UserId,
			&ach.Date,
			&ach.SportId,
			&ach.Tournament,
			&ach.Description,
			&ach.Level,
			&statsJSON,
			&ach.CertificateUrl,
		)

		if err != nil {
			log.Printf("Error scanning achievement: %v", err)
			continue
		}

		_ = json.Unmarshal(statsJSON, &ach.Stats)
		achievements = append(achievements, ach)
	}

	return achievements, nil
}

// UpdateAchievement modifies an existing achievement by ID and UserID
func (repo *Repository) UpdateAchievement(achievement *model.Achievement) error {
	query := `
		UPDATE "Achievements"
		SET date = $1, sport_id = $2, tournament_title = $3, description = $4, level = $5, stats = $6, certificate_link = $7
		WHERE id = $8 AND user_id = $9
		RETURNING date
	`

	statsJSON, err := json.Marshal(achievement.Stats)
	if err != nil {
		log.Printf("Error marshaling stats for update: %v", err)
		return fmt.Errorf("invalid stats format: %w", err)
	}

	err = repo.DB.QueryRow(query,
		achievement.Date,
		achievement.SportId,
		achievement.Tournament,
		achievement.Description,
		achievement.Level,
		statsJSON,
		achievement.CertificateUrl,
		achievement.Id,
		achievement.UserId,
	).Scan(&achievement.Date)

	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("achievement not found or unauthorized")
		}
		log.Printf("Error updating achievement: %v", err)
		return fmt.Errorf("failed to update achievement: %w", err)
	}

	return nil
}

// DeleteAchievement removes an achievement by ID and user ID
func (repo *Repository) DeleteAchievement(id, userId string) error {
	query := `DELETE FROM "Achievements" WHERE id = $1 AND user_id = $2`

	result, err := repo.DB.Exec(query, id, userId)
	if err != nil {
		log.Printf("Error deleting achievement: %v", err)
		return fmt.Errorf("failed to delete achievement: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("could not verify deletion: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("achievement not found or unauthorized")
	}

	return nil
}

// DeleteAchievementById deletes an achievement by its ID (admin or system use)
func (repo *Repository) DeleteAchievementById(id string) error {
	query := `DELETE FROM "Achievements" WHERE id = $1`
	result, err := repo.DB.Exec(query, id)
	if err != nil {
		log.Printf("Error deleting achievement by id: %v", err)
		return fmt.Errorf("failed to delete achievement: %w", err)
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("could not verify deletion: %w", err)
	}
	if rowsAffected == 0 {
		return fmt.Errorf("achievement not found")
	}
	return nil
}
