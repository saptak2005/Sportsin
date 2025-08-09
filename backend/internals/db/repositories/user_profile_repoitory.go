package repositories

import (
	"database/sql"
	"fmt"
	"log"
	"strconv"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

func (repo *Repository) CreateUserProfile(profile any) error {
	var userDetails *model.UserDetails
	var roleToSet model.Role
	var id string

	switch p := profile.(type) {
	case *model.Player:
		userDetails = &p.UserDetails
		roleToSet = model.PlayerRole
		id = p.Id
	case *model.Recruiter:
		userDetails = &p.UserDetails
		roleToSet = model.RecruiterRole
		id = p.Id
	default:
		return db.NewValidationError("profile_type", "invalid profile type provided")
	}

	if id == "" {
		return db.NewValidationError("user_id", "user ID is missing from the profile")
	}

	tx, err := repo.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "User", err)
	}
	defer tx.Rollback()

	var existingRole model.Role
	err = tx.QueryRow(`SELECT role FROM "User" WHERE id = $1`, id).Scan(&existingRole)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("ERROR: user with ID %s not found", id)
			return db.NewNotFoundError("user", id)
		}
		log.Printf("ERROR: failed to query user role: %v", err)
		return db.NewDatabaseError("select", "User", err)
	}

	if existingRole != roleToSet {
		log.Printf("ERROR: role mismatch for user %s. Expected %s, got %s", id, roleToSet, existingRole)
		return db.NewAuthorizationError("create_profile", "user profile", id)
	}

	var userDetailsExists bool
	err = tx.QueryRow(`SELECT EXISTS (SELECT 1 FROM "UserDetails" WHERE id = $1)`, id).Scan(&userDetailsExists)

	if err != nil {
		log.Printf("ERROR: failed to check if UserDetails exists: %v", err)
		return db.NewDatabaseError("select", "UserDetails", err)
	}

	if userDetailsExists {
		log.Printf("ERROR: UserDetails already exists for user %s", id)
		return db.NewAlreadyExistsError("user details", "user_id", id)
	}

	_, err = tx.Exec(`INSERT INTO "UserDetails" 
		(id, username, profile_pic, name, middlename, surname, dob, gender, about, referral_code)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		id, userDetails.UserName, userDetails.ProfilePicture, userDetails.Name, userDetails.MiddleName, userDetails.Surname, userDetails.DOB, userDetails.Gender, userDetails.About, userDetails.ReferalCode)
	if err != nil {
		log.Printf("ERROR: failed to insert into UserDetails: %v", err)
		return db.NewDatabaseError("insert", "UserDetails", err)
	}

	switch p := profile.(type) {
	case *model.Player:
		_, err = tx.Exec(`INSERT INTO "Player" (id, level, interest, interest_country) VALUES ($1, $2, $3, $4)`,
			id, p.Level, p.InterestLevel, p.InterestCountry)
		if err != nil {
			log.Printf("ERROR: failed to insert into Player: %v", err)
			return db.NewDatabaseError("insert", "Player", err)
		}
	case *model.Recruiter:
		_, err = tx.Exec(`INSERT INTO "Recruiter" (id, organization_name, organization_id, phone_no, position) VALUES ($1, $2, $3, $4, $5)`,
			id, p.OrganizationName, p.OrganizationId, p.PhoneNumber, p.Position)
		if err != nil {
			log.Printf("ERROR: failed to insert into Recruiter: %v", err)
			return db.NewDatabaseError("insert", "Recruiter", err)
		}
	}

	err = tx.Commit()
	if err != nil {
		log.Printf("ERROR: failed to commit transaction: %v", err)
		return db.NewDatabaseError("commit", "transaction", err)
	}

	return nil
}

func (repo *Repository) GetUserProfile(userId string) (any, error) {
	var role model.Role

	err := repo.DB.QueryRow(`SELECT role FROM "User" WHERE id = $1`, userId).Scan(&role)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("user", userId)
		}
		return nil, db.NewDatabaseError("select", "User", err)
	}

	switch role {
	case model.RecruiterRole:
		var recruiter model.Recruiter
		err := repo.DB.QueryRow(`
			SELECT u.id, u.email, u.role, u.created_at, u.updated_at,
			       ud.username, ud.profile_pic, ud.name, ud.middlename, ud.surname, ud.dob, ud.gender, ud.about, ud.referral_code, ud.is_premium,
			       r.organization_name, r.organization_id, r.phone_no, r.position
			FROM "User" u
			INNER JOIN "UserDetails" ud ON u.id = ud.id
			INNER JOIN "Recruiter" r ON u.id = r.id
			WHERE u.id = $1`, userId).Scan(
			&recruiter.Id, &recruiter.Email, &recruiter.Role, &recruiter.CreatedAt, &recruiter.UpdatedAt,
			&recruiter.UserDetails.UserName, &recruiter.UserDetails.ProfilePicture, &recruiter.UserDetails.Name, &recruiter.UserDetails.MiddleName, &recruiter.UserDetails.Surname, &recruiter.UserDetails.DOB, &recruiter.UserDetails.Gender, &recruiter.UserDetails.About, &recruiter.UserDetails.ReferalCode, &recruiter.UserDetails.IsPremium,
			&recruiter.OrganizationName, &recruiter.OrganizationId, &recruiter.PhoneNumber, &recruiter.Position,
		)
		if err != nil {
			if err == sql.ErrNoRows {
				return nil, db.NewNotFoundError("recruiter profile", userId)
			}
			return nil, db.NewDatabaseError("select", "Recruiter", err)
		}
		return &recruiter, nil

	case model.PlayerRole:
		var player model.Player
		err := repo.DB.QueryRow(`
			SELECT u.id, u.email, u.role, u.created_at, u.updated_at,
			       ud.username, ud.profile_pic, ud.name, ud.middlename, ud.surname, ud.dob, ud.gender, ud.about, ud.referral_code, ud.is_premium,
			       p.level, p.interest, p.interest_country
			FROM "User" u
			INNER JOIN "UserDetails" ud ON u.id = ud.id
			INNER JOIN "Player" p ON u.id = p.id
			WHERE u.id = $1`, userId).Scan(
			&player.Id, &player.Email, &player.Role, &player.CreatedAt, &player.UpdatedAt,
			&player.UserDetails.UserName, &player.UserDetails.ProfilePicture, &player.UserDetails.Name, &player.UserDetails.MiddleName, &player.UserDetails.Surname, &player.UserDetails.DOB, &player.UserDetails.Gender, &player.UserDetails.About, &player.UserDetails.ReferalCode, &player.UserDetails.IsPremium,
			&player.Level, &player.InterestLevel, &player.InterestCountry,
		)
		if err != nil {
			if err == sql.ErrNoRows {
				return nil, db.NewNotFoundError("player profile", userId)
			}
			return nil, db.NewDatabaseError("select", "Player", err)
		}
		return &player, nil

	default:
		return nil, db.NewValidationError("role", fmt.Sprintf("invalid role '%s' found for user", role))
	}
}

func (repo *Repository) UpdateProfile(profile any) error {
	var userDetails *model.UserDetails
	var id string

	switch p := profile.(type) {
	case *model.Player:
		userDetails = &p.UserDetails
		id = p.Id
	case *model.Recruiter:
		userDetails = &p.UserDetails
		id = p.Id
	default:
		return db.NewValidationError("profile_type", "invalid profile type provided")
	}

	if id == "" {
		return db.NewValidationError("user_id", "user ID is missing from the profile")
	}

	tx, err := repo.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "User", err)
	}
	defer tx.Rollback()

	res, err := tx.Exec(`UPDATE "User" SET updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		log.Printf("ERROR: failed to update user timestamp: %v", err)
		return db.NewDatabaseError("update", "User", err)
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return db.NewDatabaseError("update", "User", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("user", id)
	}

	_, err = tx.Exec(`UPDATE "UserDetails" SET 
		username = $1, profile_pic = $2, name = $3, middlename = $4, surname = $5, dob = $6, gender = $7, about = $8
		WHERE id = $9`,
		userDetails.UserName, userDetails.ProfilePicture, userDetails.Name, userDetails.MiddleName, userDetails.Surname, userDetails.DOB, userDetails.Gender, userDetails.About, id)
	if err != nil {
		log.Printf("ERROR: failed to update UserDetails: %v", err)
		return db.NewDatabaseError("update", "UserDetails", err)
	}

	switch p := profile.(type) {
	case *model.Player:
		_, err = tx.Exec(`UPDATE "Player" SET
			level = $1, interest = $2, interest_country = $3
			WHERE id = $4`,
			p.Level, p.InterestLevel, p.InterestCountry, id)
		if err != nil {
			log.Printf("ERROR: failed to update Player details: %v", err)
			return db.NewDatabaseError("update", "Player", err)
		}
	case *model.Recruiter:
		_, err = tx.Exec(`UPDATE "Recruiter" SET
			organization_name = $1, organization_id = $2, phone_no = $3, position = $4
			WHERE id = $5`,
			p.OrganizationName, p.OrganizationId, p.PhoneNumber, p.Position, id)
		if err != nil {
			log.Printf("ERROR: failed to update Recruiter details: %v", err)
			return db.NewDatabaseError("update", "Recruiter", err)
		}
	}

	err = tx.Commit()
	if err != nil {
		log.Printf("ERROR: failed to commit transaction: %v", err)
		return db.NewDatabaseError("commit", "transaction", err)
	}

	return nil
}

func (repo *Repository) UpdateProfilePicture(email string, imageUrl string) error {
	tx, err := repo.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "User", err)
	}
	defer tx.Rollback()

	var userId string
	err = tx.QueryRow(`SELECT id FROM "User" WHERE email = $1`, email).Scan(&userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewNotFoundError("user", email)
		}
		log.Printf("ERROR: failed to get user ID: %v", err)
		return db.NewDatabaseError("select", "User", err)
	}

	res, err := tx.Exec(`UPDATE "UserDetails" SET profile_pic = $1 WHERE id = $2`, imageUrl, userId)
	if err != nil {
		log.Printf("ERROR: failed to update UserDetails: %v", err)
		return db.NewDatabaseError("update", "UserDetails", err)
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return db.NewDatabaseError("update", "UserDetails", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("user details", userId)
	}

	err = tx.Commit()
	if err != nil {
		log.Printf("ERROR: failed to commit transaction: %v", err)
		return db.NewDatabaseError("commit", "transaction", err)
	}

	log.Printf("UserDetails updated for user %s", userId)
	return nil
}

func (repo *Repository) GetUserIdByReferalCode(referralCode string) (string, error) {
	var userId string
	err := repo.DB.QueryRow(`SELECT id FROM "UserDetails" WHERE referral_code = $1`, referralCode).Scan(&userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", db.NewNotFoundError("user", referralCode)
		}
		return "", db.NewDatabaseError("select", "UserDetails", err)
	}
	return userId, nil
}

func (repo *Repository) ReferalCodeExists(referralCode string) (bool, error) {
	var exists bool
	err := repo.DB.QueryRow(`SELECT EXISTS (SELECT 1 FROM "UserDetails" WHERE referral_code = $1)`, referralCode).Scan(&exists)
	if err != nil {
		return false, db.NewDatabaseError("select", "UserDetails", err)
	}
	return exists, nil
}

func (repo *Repository) UserHasReferalCode(userId string) (bool, error) {
	var exists bool
	err := repo.DB.QueryRow(`SELECT EXISTS (SELECT 1 FROM "UserDetails" WHERE id = $1 AND referral_code IS NOT NULL)`, userId).Scan(&exists)
	if err != nil {
		return false, db.NewDatabaseError("select", "UserDetails", err)
	}
	return exists, nil
}

func (repo *Repository) CreateReferalCode(userId, referalCode string) error {
	_, err := repo.DB.Exec(`UPDATE "UserDetails" SET referral_code = $1 WHERE id = $2`, referalCode, userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewNotFoundError("user", userId)
		}
		return db.NewDatabaseError("update", "UserDetails", err)
	}
	return nil
}

func (repo *Repository) GetReferalCode(userId string) (string, error) {
	var referralCode string
	err := repo.DB.QueryRow(`SELECT referral_code FROM "UserDetails" WHERE id = $1`, userId).Scan(&referralCode)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", db.NewNotFoundError("user", userId)
		}
		return "", db.NewDatabaseError("select", "UserDetails", err)
	}

	return referralCode, nil
}

func (repo *Repository) ReferUser(userId, referalCode string) error {
	tx, err := repo.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "User", err)
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			tx.Commit()
		}
	}()
	var referalUserId string
	err = tx.QueryRow(`SELECT id FROM "UserDetails" WHERE referral_code = $1`, referalCode).Scan(&referalUserId)
	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewNotFoundError("user", referalCode)
		}
		return db.NewDatabaseError("select", "UserDetails", err)
	}
	_, err = tx.Exec(`UPDATE "UserDetails" SET referred_by = $1 WHERE id = $2`, referalUserId, userId)
	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewNotFoundError("user", userId)
		}
		return db.NewDatabaseError("update", "UserDetails", err)
	}
	var referalRewardString string
	err = tx.QueryRow("SELECT value from Meta where key = referal_reward").Scan(&referalRewardString)
	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewNotFoundError("referal_reward", "referal_reward")
		}
		return db.NewDatabaseError("select", "Meta", err)
	}
	var referalReward int
	referalReward, err = strconv.Atoi(referalRewardString)
	if err != nil {
		return db.NewValidationError("referal_reward", "referal_reward")
	}

	_, err = tx.Exec(`UPDATE "UserDetails" SET coins = coins + $1 WHERE id = $2`, referalReward, referalUserId)
	return nil
}

func (re *Repository) UsernameExists(username string) (bool, error) {
	var exists bool
	err := re.DB.QueryRow(`SELECT EXISTS (SELECT 1 FROM "UserDetails" WHERE username = $1)`, username).Scan(&exists)
	if err != nil {
		return false, db.NewDatabaseError("select", "UserDetails", err)
	}
	return exists, nil
}
