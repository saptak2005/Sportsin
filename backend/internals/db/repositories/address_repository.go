package repositories

import (
	"log"

	"sportsin_backend/internals/model"
)

func (repo *Repository) CreateAddress(userId string, address *model.Address) error {
	db := repo.DB
	tx, err := db.Begin()
	if err != nil {
		log.Println("Error starting transaction:", err)
		return err
	}
	_, err = tx.Exec(
		"INSERT INTO \"Address\" (user_id, country, state, city, street, building, pincode) VALUES ($1, $2, $3, $4, $5, $6, $7)",
		userId, address.Country,
		address.State, address.City, address.Street,
		address.Building, address.PostalCode,
	)
	if err != nil {
		log.Println("Error inserting address:", err)
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

func (repo *Repository) GetAddressesByUserId(userId string) ([]model.Address, error) {
	db := repo.DB
	rows, err := db.Query("SELECT id, user_id, country, state, city, street, building, pincode FROM \"Address\" WHERE user_id = $1", userId)
	if err != nil {
		log.Println("Error querying addresses:", err)
		return nil, err
	}
	defer rows.Close()

	var addresses []model.Address
	for rows.Next() {
		var address model.Address
		if err := rows.Scan(&address.Id, &address.UserId, &address.Country, &address.State, &address.City, &address.Street, &address.Building, &address.PostalCode); err != nil {
			log.Println("Error scanning address:", err)
			return nil, err
		}
		addresses = append(addresses, address)
	}

	if err := rows.Err(); err != nil {
		log.Println("Error with rows:", err)
		return nil, err
	}

	return addresses, nil
}

func (repo *Repository) DeleteAddressById(addressId string) error {
	db := repo.DB
	tx, err := db.Begin()
	if err != nil {
		log.Println("Error starting transaction:", err)
		return err
	}
	_, err = tx.Exec("DELETE FROM \"Address\" WHERE id = $1", addressId)
	if err != nil {
		log.Println("Error deleting address:", err)
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
