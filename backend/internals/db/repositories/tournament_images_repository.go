package repositories

import (
	"database/sql"
	"fmt"
	"log"

	"sportsin_backend/internals/db"
)

// TournamentImage represents a tournament image
type TournamentImage struct {
	Id           string `json:"id"`
	TournamentId string `json:"tournament_id"`
	ImageUrl     string `json:"image_url"`
}

// AddTournamentImage adds an image to a tournament
func (repo *Repository) AddTournamentImage(tournamentImage *TournamentImage) error {
	query := `INSERT INTO "TournamentImages" (id, tournament_id, image_url)
	VALUES ($1, $2, $3)`

	_, err := repo.DB.Exec(query,
		tournamentImage.Id,
		tournamentImage.TournamentId,
		tournamentImage.ImageUrl,
	)

	if err != nil {
		log.Printf("ERROR: failed to add tournament image: %v", err)
		return fmt.Errorf("AddTournamentImage: %w", err)
	}

	return nil
}

// GetTournamentImages retrieves all images for a tournament
func (repo *Repository) GetTournamentImages(tournamentID string) ([]*TournamentImage, error) {
	query := `SELECT id, tournament_id, image_url 
	FROM "TournamentImages" WHERE tournament_id = $1`

	rows, err := repo.DB.Query(query, tournamentID)
	if err != nil {
		log.Printf("ERROR: failed to get tournament images: %v", err)
		return nil, fmt.Errorf("GetTournamentImages: %w", err)
	}
	defer rows.Close()

	var images []*TournamentImage
	for rows.Next() {
		var image TournamentImage
		err := rows.Scan(
			&image.Id,
			&image.TournamentId,
			&image.ImageUrl,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan tournament image: %v", err)
			return nil, fmt.Errorf("GetTournamentImages: %w", err)
		}
		images = append(images, &image)
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: row iteration error: %v", err)
		return nil, fmt.Errorf("GetTournamentImages: %w", err)
	}

	return images, nil
}

// DeleteTournamentImage deletes a tournament image by ID
func (repo *Repository) DeleteTournamentImage(imageID string) error {
	query := `DELETE FROM "TournamentImages" WHERE id = $1`

	result, err := repo.DB.Exec(query, imageID)
	if err != nil {
		log.Printf("ERROR: failed to delete tournament image: %v", err)
		return fmt.Errorf("DeleteTournamentImage: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return fmt.Errorf("DeleteTournamentImage: %w", err)
	}

	if rowsAffected == 0 {
		return db.ITEM_NOT_FOUND
	}

	return nil
}

// DeleteAllTournamentImages deletes all images for a tournament
func (repo *Repository) DeleteAllTournamentImages(tournamentID string) error {
	query := `DELETE FROM "TournamentImages" WHERE tournament_id = $1`

	_, err := repo.DB.Exec(query, tournamentID)
	if err != nil {
		log.Printf("ERROR: failed to delete all tournament images: %v", err)
		return fmt.Errorf("DeleteAllTournamentImages: %w", err)
	}

	return nil
}

// GetTournamentImageByID retrieves a specific tournament image
func (repo *Repository) GetTournamentImageByID(imageID string) (*TournamentImage, error) {
	var image TournamentImage
	query := `SELECT id, tournament_id, image_url 
	FROM "TournamentImages" WHERE id = $1`

	err := repo.DB.QueryRow(query, imageID).Scan(
		&image.Id,
		&image.TournamentId,
		&image.ImageUrl,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.ITEM_NOT_FOUND
		}
		log.Printf("ERROR: failed to get tournament image by ID: %v", err)
		return nil, fmt.Errorf("GetTournamentImageByID: %w", err)
	}

	return &image, nil
}
