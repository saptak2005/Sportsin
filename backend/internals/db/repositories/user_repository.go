package repositories

import (
	"database/sql"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

func (repo *Repository) CreateUserOnSignup(userId, email string, role model.Role) error {
	username := email
	_, err := repo.DB.Exec(`INSERT INTO "User" (id, username, email, role)
	VALUES ($1, $2, $3, $4)`,
		userId, username, email, role)
	if err != nil {
		log.Printf("ERROR: failed to create user: %v", err)
		// Check for unique constraint violations
		if db.IsUniqueConstraintError(err, "email") {
			return db.NewAlreadyExistsError("user", "email", email)
		}
		if db.IsUniqueConstraintError(err, "username") {
			return db.NewAlreadyExistsError("user", "username", username)
		}
		return db.NewDatabaseError("insert", "User", err)
	}
	return nil
}

func (repo *Repository) AddUserDeviceTokenDetails(userID, deviceToken, snsEndpoint string) error {
	_, err := repo.DB.Exec(`UPDATE "User" SET device_token = $1, sns_endpoint_arn = $2 WHERE id = $3`,
		deviceToken, snsEndpoint, userID)
	if err != nil {
		log.Printf("ERROR: failed to add user device token details: %v", err)
		return db.NewDatabaseError("update", "User", err)
	}
	return nil
}

func (repo *Repository) GetUserByID(userID string) (*model.User, error) {
	var user model.User
	err := repo.DB.QueryRow(`SELECT id, username, email, role, created_at, updated_at, sns_endpoint_arn, device_token FROM "User" WHERE id = $1`, userID).Scan(
		&user.Id, &user.Username, &user.Email, &user.Role, &user.CreatedAt, &user.UpdatedAt, &user.SnsEndpointArn, &user.DeviceToken,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("user", userID)
		}
		log.Printf("ERROR: failed to get user by ID: %v", err)
		return nil, db.NewDatabaseError("select", "User", err)
	}

	return &user, nil
}

func (repo *Repository) GetUserByEmail(email string) (*model.User, error) {
	var user model.User
	err := repo.DB.QueryRow(`SELECT id, username, email, role, created_at, updated_at FROM "User" WHERE email = $1`, email).Scan(
		&user.Id, &user.Username, &user.Email, &user.Role, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("user", email)
		}
		log.Printf("ERROR: failed to get user by email: %v", err)
		return nil, db.NewDatabaseError("select", "User", err)
	}

	return &user, nil
}
