package db

import (
	"database/sql"

	_ "github.com/lib/pq"
	"sportsin_backend/internals/config"
)

func Connect(cfg *config.Config) (*sql.DB, error) {
	return sql.Open("postgres", cfg.DATABASE_URL)
}
