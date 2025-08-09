package services

import (
	"database/sql"
)

type UserSearchResult struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Username  string `json:"username"`
	Image     string `json:"image"`
	IsPremium bool   `json:"is_premium"`
}

func SearchUsers(db *sql.DB, query string) ([]UserSearchResult, error) {
	_, _ = db.Exec("SELECT refresh_user_search_index()")

	rows, err := db.Query(`SELECT u.id, u.name, u.username, d.profile_pic, d.is_premium FROM user_search_index u LEFT JOIN "UserDetails" d ON u.id = d.id WHERE u.name ILIKE '%' || $1 || '%' OR u.username ILIKE '%' || $1 || '%' LIMIT 20`, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []UserSearchResult
	for rows.Next() {
		var u UserSearchResult
		var name, image sql.NullString
		if err := rows.Scan(&u.ID, &name, &u.Username, &image, &u.IsPremium); err != nil {
			return nil, err
		}
		u.Name = ""
		if name.Valid {
			u.Name = name.String
		}
		u.Image = ""
		if image.Valid {
			u.Image = image.String
		}
		results = append(results, u)
	}
	return results, nil
}
