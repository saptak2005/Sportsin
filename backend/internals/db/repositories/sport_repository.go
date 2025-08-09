package repositories

import (
	"database/sql"
	"strings"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

func (r *Repository) GetSports(limit, offset int) ([]model.Sport, error) {
	res, err := r.DB.Query(`SELECT id, name, description, created_at, updated_at FROM "Sports" ORDER BY created_at DESC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, err
	}

	sports := []model.Sport{}

	for res.Next() {
		var sport model.Sport
		err := res.Scan(&sport.Id, &sport.Name, &sport.Description, &sport.CreatedAt, &sport.UpdatedAt)
		if err != nil {
			return nil, err
		}
		sports = append(sports, sport)
	}

	return sports, nil
}

func (r *Repository) GetSportById(id string) (*model.Sport, error) {
	var sport model.Sport
	err := r.DB.QueryRow(`SELECT id, name, description, created_at, updated_at FROM "Sports" WHERE id = $1`, id).Scan(&sport.Id, &sport.Name, &sport.Description, &sport.CreatedAt, &sport.UpdatedAt)
	if err != nil {
		return nil, err
	}

	return &sport, nil
}

func (r *Repository) GetSportByName(name string) (*model.Sport, error) {
	var sport model.Sport
	sname, err := sanitizeSportName(name)
	if err != nil {
		return nil, err
	}
	err = r.DB.QueryRow(`SELECT id, name, description, created_at, updated_at FROM "Sports" WHERE name = $1`, sname).Scan(&sport.Id, &sport.Name, &sport.Description, &sport.CreatedAt, &sport.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("sport", name)
		}
		return nil, err
	}
	return &sport, nil
}

func (r *Repository) CreateSport(sport *model.Sport) (string, error) {
	sname, err := sanitizeSportName(sport.Name)
	if err != nil {
		return "", err
	}
	sport.Name = sname
	err = r.DB.QueryRow(`INSERT INTO "Sports" (id, name, description) VALUES (gen_random_uuid(), $1, $2) RETURNING id`, sport.Name, sport.Description).Scan(&sport.Id)
	if err != nil {
		if db.IsUniqueConstraintError(err, "name") {
			return "", db.NewAlreadyExistsError("sport", "name", sport.Name)
		}
		return "", err
	}
	return sport.Id, nil
}

func sanitizeSportName(name string) (string, error) {
	name = strings.Trim(name, " ")
	name = strings.ReplaceAll(name, " ", "_")
	if strings.ContainsAny(name, "!@#$%^&*()+") {
		return "", db.NewValidationError("sport", "Invalid name")
	}
	return strings.ToLower(name), nil

}
