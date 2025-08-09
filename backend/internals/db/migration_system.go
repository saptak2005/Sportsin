package db

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

type MigrationEntry struct {
	Name      string `json:"name"`
	SQLUp     string `json:"sql_up"`
	SQLDown   string `json:"sql_down,omitempty"`
	CreatedAt string `json:"created_at,omitempty"`
	AppliedAt string `json:"applied_at,omitempty"`
}

func getMigrationFiles(path string) ([]string, error) {
	files, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var migrationFiles []string
	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".up.sql") {
			// Extract base name without .up.sql suffix
			baseName := strings.TrimSuffix(file.Name(), ".up.sql")
			migrationFiles = append(migrationFiles, baseName)
		}
	}
	sort.Strings(migrationFiles)
	return migrationFiles, nil
}

func LoadMigrations(path string) ([]MigrationEntry, error) {
	files, err := getMigrationFiles(path)
	if err != nil {
		return nil, err
	}

	var migrations []MigrationEntry
	for _, baseName := range files {
		upFile := baseName + ".up.sql"
		downFile := baseName + ".down.sql"

		// Read up migration
		upContent, err := os.ReadFile(filepath.Join(path, upFile))
		if err != nil {
			return nil, fmt.Errorf("failed to read up migration file %s: %w", upFile, err)
		}

		// Read down migration (optional)
		var downContent []byte
		downFilePath := filepath.Join(path, downFile)
		if _, err := os.Stat(downFilePath); err == nil {
			downContent, err = os.ReadFile(downFilePath)
			if err != nil {
				return nil, fmt.Errorf("failed to read down migration file %s: %w", downFile, err)
			}
		}

		// Extract timestamp from filename (assumes format: YYYYMMDDHHMMSS_description)
		var createdAt string
		if parts := strings.Split(baseName, "_"); len(parts) > 0 {
			createdAt = parts[0]
		}

		migrations = append(migrations, MigrationEntry{
			Name:      baseName,
			SQLUp:     string(upContent),
			SQLDown:   string(downContent),
			CreatedAt: createdAt,
			AppliedAt: "",
		})
	}
	return migrations, nil
}

func CreateMigrationTableIfNotExists(db *sql.DB) error {
	query := `
	CREATE TABLE IF NOT EXISTS migrations (
		name TEXT PRIMARY KEY,
		sql_up TEXT NOT NULL,
		sql_down TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		applied_at TIMESTAMP
	);
	`
	_, err := db.Exec(query)
	return err
}

func RunMigrations(db *sql.DB) error {
	return RunMigrationsFromPath(db, "migrations")
}

func RunMigrationsFromPath(db *sql.DB, migrationPath string) error {
	if err := CreateMigrationTableIfNotExists(db); err != nil {
		return fmt.Errorf("failed to create migrations table: %w", err)
	}

	migrations, err := LoadMigrations(migrationPath)
	if err != nil {
		return fmt.Errorf("failed to load migrations: %w", err)
	}

	if len(migrations) == 0 {
		log.Printf("No migrations found in %s", migrationPath)
		return nil
	}

	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	// Defer a rollback. If the transaction is successfully committed, this will
	// be a no-op that returns sql.ErrTxDone.
	defer func() {
		if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
			log.Printf("Failed to rollback transaction: %v", err)
		}
	}()

	// Get all applied migrations in a single query.
	rows, err := tx.Query("SELECT name FROM migrations")
	if err != nil {
		return fmt.Errorf("failed to query for applied migrations: %w", err)
	}

	appliedMigrations := make(map[string]bool)
	for rows.Next() {
		var name string
		if err = rows.Scan(&name); err != nil {
			rows.Close()
			return fmt.Errorf("failed to scan applied migration name: %w", err)
		}
		appliedMigrations[name] = true
	}
	rows.Close()
	if err = rows.Err(); err != nil {
		return fmt.Errorf("error iterating over applied migrations: %w", err)
	}

	appliedCount := 0
	for _, migration := range migrations {
		if appliedMigrations[migration.Name] {
			log.Printf("Migration %s already applied, skipping", migration.Name)
			continue
		}

		log.Printf("Applying migration: %s", migration.Name)
		if _, err := tx.Exec(migration.SQLUp); err != nil {
			return fmt.Errorf("failed to execute migration %s: %w", migration.Name, err)
		}

		// Convert timestamp string to proper datetime format
		var createdAtTime time.Time
		if migration.CreatedAt != "" {
			parsedTime, err := time.Parse("20060102150405", migration.CreatedAt)
			if err != nil {
				log.Printf("Warning: failed to parse migration timestamp %s, using current time: %v", migration.CreatedAt, err)
				createdAtTime = time.Now()
			} else {
				createdAtTime = parsedTime
			}
		} else {
			createdAtTime = time.Now()
		}

		if _, err := tx.Exec("INSERT INTO migrations (name, sql_up, sql_down, created_at, applied_at) VALUES ($1, $2, $3, $4, NOW())",
			migration.Name, migration.SQLUp, migration.SQLDown, createdAtTime); err != nil {
			return fmt.Errorf("failed to insert migration record for %s: %w", migration.Name, err)
		}
		appliedCount++
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	if appliedCount > 0 {
		log.Printf("✅ Successfully applied %d migration(s)", appliedCount)
	} else {
		log.Println("✅ All migrations already applied")
	}
	return nil
}

func CreateMigrationFile(migrationPath, name string) (string, string, error) {
	if err := os.MkdirAll(migrationPath, 0755); err != nil {
		return "", "", fmt.Errorf("failed to create migration directory: %w", err)
	}

	timestamp := time.Now().Format("20060102150405")
	baseName := fmt.Sprintf("%s_%s", timestamp, name)
	upFilename := fmt.Sprintf("%s.up.sql", baseName)
	downFilename := fmt.Sprintf("%s.down.sql", baseName)

	upFilePath := filepath.Join(migrationPath, upFilename)
	downFilePath := filepath.Join(migrationPath, downFilename)

	// Create up migration file
	upFile, err := os.Create(upFilePath)
	if err != nil {
		return "", "", fmt.Errorf("failed to create up migration file: %w", err)
	}
	defer upFile.Close()

	upTemplate := fmt.Sprintf(`-- Migration: %s (UP)
-- Created: %s

-- Add your SQL migration here
-- Example:
-- CREATE TABLE example (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name VARCHAR(255) NOT NULL
-- );

`, name, time.Now().Format("2006-01-02 15:04:05"))

	if _, err := upFile.WriteString(upTemplate); err != nil {
		return "", "", fmt.Errorf("failed to write up migration template: %w", err)
	}

	// Create down migration file
	downFile, err := os.Create(downFilePath)
	if err != nil {
		return "", "", fmt.Errorf("failed to create down migration file: %w", err)
	}
	defer downFile.Close()

	downTemplate := fmt.Sprintf(`-- Migration: %s (DOWN)
-- Created: %s

-- Add your rollback SQL here
-- Example:
-- DROP TABLE IF EXISTS example;

`, name, time.Now().Format("2006-01-02 15:04:05"))

	if _, err := downFile.WriteString(downTemplate); err != nil {
		return "", "", fmt.Errorf("failed to write down migration template: %w", err)
	}

	return upFilePath, downFilePath, nil
}

// GetAppliedMigrations returns a list of applied migrations in reverse order (newest first)
func GetAppliedMigrations(db *sql.DB) ([]MigrationEntry, error) {
	query := `
	SELECT name, sql_up, COALESCE(sql_down, ''), created_at, applied_at 
	FROM migrations 
	WHERE applied_at IS NOT NULL 
	ORDER BY created_at DESC
	`

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query applied migrations: %w", err)
	}
	defer rows.Close()

	var migrations []MigrationEntry
	for rows.Next() {
		var migration MigrationEntry
		var appliedAt sql.NullTime

		err := rows.Scan(&migration.Name, &migration.SQLUp, &migration.SQLDown,
			&migration.CreatedAt, &appliedAt)
		if err != nil {
			return nil, fmt.Errorf("failed to scan migration row: %w", err)
		}

		if appliedAt.Valid {
			migration.AppliedAt = appliedAt.Time.Format("2006-01-02 15:04:05")
		}

		migrations = append(migrations, migration)
	}

	return migrations, nil
}

// RollbackMigration rolls back a specific migration
func RollbackMigration(db *sql.DB, migrationName string) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if err := tx.Rollback(); err != nil {
			log.Printf("Failed to rollback transaction: %v", err)
		}
	}()

	// Get the migration details
	var migration MigrationEntry
	var appliedAt sql.NullTime
	err = tx.QueryRow(`
		SELECT name, sql_up, COALESCE(sql_down, ''), created_at, applied_at 
		FROM migrations 
		WHERE name = $1 AND applied_at IS NOT NULL
	`, migrationName).Scan(&migration.Name, &migration.SQLUp, &migration.SQLDown,
		&migration.CreatedAt, &appliedAt)

	if err == sql.ErrNoRows {
		return fmt.Errorf("migration %s not found or not applied", migrationName)
	}
	if err != nil {
		return fmt.Errorf("failed to get migration details: %w", err)
	}

	if migration.SQLDown == "" {
		return fmt.Errorf("migration %s has no down SQL - cannot rollback", migrationName)
	}

	log.Printf("Rolling back migration: %s", migration.Name)

	// Execute the down migration
	if _, err := tx.Exec(migration.SQLDown); err != nil {
		return fmt.Errorf("failed to execute rollback for %s: %w", migration.Name, err)
	}

	// Remove migration from applied migrations table
	if _, err := tx.Exec("DELETE FROM migrations WHERE name = $1", migration.Name); err != nil {
		return fmt.Errorf("failed to remove migration record for %s: %w", migration.Name, err)
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit rollback transaction: %w", err)
	}

	log.Printf("✅ Successfully rolled back migration: %s", migration.Name)
	return nil
}

// RollbackLastMigration rolls back the most recently applied migration
func RollbackLastMigration(db *sql.DB) error {
	migrations, err := GetAppliedMigrations(db)
	if err != nil {
		return fmt.Errorf("failed to get applied migrations: %w", err)
	}

	if len(migrations) == 0 {
		return fmt.Errorf("no migrations to rollback")
	}

	return RollbackMigration(db, migrations[0].Name)
}

// RollbackToMigration rolls back all migrations after the specified migration
func RollbackToMigration(db *sql.DB, targetMigration string) error {
	migrations, err := GetAppliedMigrations(db)
	if err != nil {
		return fmt.Errorf("failed to get applied migrations: %w", err)
	}

	// Find the target migration
	targetIndex := -1
	for i, migration := range migrations {
		if migration.Name == targetMigration {
			targetIndex = i
			break
		}
	}

	if targetIndex == -1 {
		return fmt.Errorf("target migration %s not found in applied migrations", targetMigration)
	}

	// Rollback migrations in reverse order (newest first)
	rolledBack := 0
	for i := 0; i < targetIndex; i++ {
		if err := RollbackMigration(db, migrations[i].Name); err != nil {
			return fmt.Errorf("failed to rollback migration %s: %w", migrations[i].Name, err)
		}
		rolledBack++
	}

	if rolledBack > 0 {
		log.Printf("✅ Successfully rolled back %d migration(s) to %s", rolledBack, targetMigration)
	} else {
		log.Printf("✅ Already at target migration %s", targetMigration)
	}

	return nil
}
