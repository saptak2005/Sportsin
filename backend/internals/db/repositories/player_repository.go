package repositories

import (
	"log"

	"sportsin_backend/internals/model"
)

func (repo *Repository) CreatePlayer(player *model.Player) error {
	db := repo.DB
	tx, err := db.Begin()
	if err != nil {
		return err
	}

	_, err = tx.Exec(`INSERT INTO "Player" (id, level, interest, interest_country) VALUES ($1, $2, $3, $4)`,
		player.Id, player.Level, player.InterestLevel, player.InterestCountry)

	if err != nil {
		log.Println("Error inserting player:", err)
		tx.Rollback()
		return err
	}

	err = tx.Commit()
	if err != nil {
		log.Println("Error committing transaction:", err)
		tx.Rollback()
		return err
	}
	return nil
}

func (repo *Repository) GetPlayerByUserId(userId string) (*model.Player, error) {
	db := repo.DB
	row := db.QueryRow(`SELECT  id, level, interest, interest_country FROM "Player" WHERE id = $1`, userId)

	var player model.Player
	if err := row.Scan(&player.Id, &player.Level, &player.InterestLevel, &player.InterestCountry); err != nil {
		log.Println("Error scanning player:", err)
		return nil, err
	}

	return &player, nil
}

func (repo *Repository) UpdatePlayer(player *model.Player) error {
	db := repo.DB
	tx, err := db.Begin()
	if err != nil {
		log.Println("Error starting transaction:", err)
		return err
	}

	_, err = tx.Exec(`UPDATE "Player" SET level = $2, interest = $3, interest_country = $4 WHERE id = $1`,
		player.Id, player.Level, player.InterestLevel, player.InterestCountry)
	if err != nil {
		log.Println("Error updating player:", err)
		tx.Rollback()
		return err
	}

	err = tx.Commit()

	if err != nil {
		log.Println("Error committing transaction:", err)
		tx.Rollback()
		return err
	}

	return nil
}

func (repo *Repository) DeletePlayerByUserId(userId string) error {
	db := repo.DB
	tx, err := db.Begin()
	if err != nil {
		log.Println("Error starting transaction:", err)
		return err
	}

	_, err = tx.Exec(`DELETE FROM "Player" WHERE id = $1`, userId)
	if err != nil {
		log.Println("Error deleting player:", err)
		tx.Rollback()
		return err

	}

	if err := tx.Commit(); err != nil {
		log.Println("Error committing transaction:", err)
		tx.Rollback()
		return err
	}

	return nil
}
