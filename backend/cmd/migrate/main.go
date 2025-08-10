package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/joho/godotenv"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
)

func main() {
	var (
		command = flag.String("command", "", "Command to run: create, up, down, status, rollback-to")
		name    = flag.String("name", "", "Name of the migration (required for create)")
		path    = flag.String("path", "migrations", "Path where migration files are located")
		steps   = flag.Int("steps", 1, "Number of migrations to rollback (for down command)")
		target  = flag.String("target", "", "Target migration name to rollback to (for rollback-to command)")
		help    = flag.Bool("help", false, "Show help message")
	)
	flag.Parse()

	if *help {
		showHelp()
		return
	}

	if *command == "" {
		fmt.Fprintf(os.Stderr, "Error: command is required\n\n")
		showHelp()
		os.Exit(1)
	}

	switch *command {
	case "create":
		createMigration(*name, *path)
	case "up":
		runMigrationsUp(*path)
	case "down":
		runMigrationsDown(*path, *steps)
	case "rollback-to":
		rollbackToMigration(*path, *target)
	case "status":
		showMigrationStatus(*path)
	default:
		fmt.Fprintf(os.Stderr, "Error: unknown command '%s'\n\n", *command)
		showHelp()
		os.Exit(1)
	}
}

func createMigration(name, migrationPath string) {
	if name == "" {
		fmt.Fprintf(os.Stderr, "Error: migration name is required for create command\n")
		os.Exit(1)
	}

	// Clean the migration name - replace spaces with underscores and lowercase
	cleanName := strings.ToLower(strings.ReplaceAll(strings.TrimSpace(name), " ", "_"))
	if cleanName == "" {
		fmt.Fprintf(os.Stderr, "Error: migration name cannot be empty\n")
		os.Exit(1)
	}

	// Get absolute path for migrations
	absPath, err := filepath.Abs(migrationPath)
	if err != nil {
		log.Fatalf("Error resolving migration path: %v", err)
	}

	// Create the migration file
	upFilePath, downFilePath, err := db.CreateMigrationFile(absPath, cleanName)
	if err != nil {
		log.Fatalf("Error creating migration file: %v", err)
	}

	fmt.Printf("✅ Migration files created successfully!\n")
	fmt.Printf("📁 Up file: %s\n", upFilePath)
	fmt.Printf("📁 Down file: %s\n", downFilePath)
	fmt.Printf("💡 Edit the files to add your SQL migration and rollback\n")
	fmt.Printf("🚀 Run migrations with: make migrate-up\n")
}

func runMigrationsUp(migrationPath string) {
	fmt.Println("🚀 Running database migrations...")

	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Connect to database
	cfg := config.LoadConfig()
	conn, err := db.Connect(cfg)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}
	defer conn.Close()

	// Run migrations
	err = db.RunMigrationsFromPath(conn, migrationPath)
	if err != nil {
		log.Fatal("Error running migrations:", err)
	}

	fmt.Println("✅ Migrations completed successfully!")
}

func runMigrationsDown(migrationPath string, steps int) {
	fmt.Printf("⬇️  Rolling back %d migration(s)...\n", steps)

	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Connect to database
	cfg := config.LoadConfig()
	conn, err := db.Connect(cfg)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}
	defer conn.Close()

	// Get applied migrations
	appliedMigrations, err := db.GetAppliedMigrations(conn)
	if err != nil {
		log.Fatal("Error getting applied migrations:", err)
	}

	if len(appliedMigrations) == 0 {
		fmt.Println("ℹ️  No migrations to rollback")
		return
	}

	if steps > len(appliedMigrations) {
		fmt.Printf("⚠️  Only %d migration(s) available to rollback, adjusting steps\n", len(appliedMigrations))
		steps = len(appliedMigrations)
	}

	// Rollback the specified number of migrations
	for i := 0; i < steps; i++ {
		if err := db.RollbackLastMigration(conn); err != nil {
			log.Fatalf("Error rolling back migration: %v", err)
		}
	}

	fmt.Printf("✅ Successfully rolled back %d migration(s)!\n", steps)
}

func rollbackToMigration(migrationPath, target string) {
	if target == "" {
		fmt.Fprintf(os.Stderr, "Error: target migration name is required for rollback-to command\n")
		os.Exit(1)
	}

	fmt.Printf("⬇️  Rolling back to migration: %s\n", target)

	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Connect to database
	cfg := config.LoadConfig()
	conn, err := db.Connect(cfg)
	if err != nil {
		log.Fatal("Error connecting to database:", err)
	}
	defer conn.Close()

	// Rollback to the specified migration
	if err := db.RollbackToMigration(conn, target); err != nil {
		log.Fatalf("Error rolling back to migration: %v", err)
	}

	fmt.Printf("✅ Successfully rolled back to migration: %s\n", target)
}

func showMigrationStatus(migrationPath string) {
	fmt.Println("📊 Checking migration status...")

	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// Connect to database
	cfg := config.LoadConfig()
	conn, err := db.Connect(cfg)
	if err != nil {
		log.Printf("Error connecting to database: %v", err)
		return
	}
	defer conn.Close()

	// Check if migration directory exists
	if _, err := os.Stat(migrationPath); os.IsNotExist(err) {
		fmt.Printf("📁 No migrations directory found at: %s\n", migrationPath)
		return
	}

	// Load migration files
	migrations, err := db.LoadMigrations(migrationPath)
	if err != nil {
		log.Printf("Error loading migrations: %v", err)
		return
	}

	if len(migrations) == 0 {
		fmt.Printf("📁 No migration files found in: %s\n", migrationPath)
		return
	}

	// Get applied migrations
	appliedMigrations, err := db.GetAppliedMigrations(conn)
	if err != nil {
		log.Printf("Error getting applied migrations: %v", err)
		return
	}

	// Create a map of applied migrations for quick lookup
	appliedMap := make(map[string]bool)
	for _, applied := range appliedMigrations {
		appliedMap[applied.Name] = true
	}

	fmt.Printf("📁 Found %d migration file(s) in: %s\n", len(migrations), migrationPath)
	fmt.Printf("📋 Applied migrations: %d\n", len(appliedMigrations))
	fmt.Println()

	for i, migration := range migrations {
		status := "❌ Not applied"
		if appliedMap[migration.Name] {
			status = "✅ Applied"
		}
		fmt.Printf("  %d. %s - %s (created: %s)\n", i+1, migration.Name, status, migration.CreatedAt)
	}
}

func showHelp() {
	fmt.Println("🏈 SportsIN Migration Manager")
	fmt.Println()
	fmt.Println("Manages database migrations for SportsIN Backend")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  go run cmd/migrate/main.go -command=<command> [options]")
	fmt.Println()
	fmt.Println("Commands:")
	fmt.Println("  create       Create a new migration file pair (up and down)")
	fmt.Println("  up           Run pending migrations")
	fmt.Println("  down         Rollback the specified number of migrations")
	fmt.Println("  rollback-to  Rollback to a specific migration")
	fmt.Println("  status       Show migration status")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  -command string")
	fmt.Println("        Command to run: create, up, down, rollback-to, status (required)")
	fmt.Println("  -name string")
	fmt.Println("        Name of the migration (required for create command)")
	fmt.Println("  -path string")
	fmt.Println("        Path where migration files are located (default: migrations)")
	fmt.Println("  -steps int")
	fmt.Println("        Number of migrations to rollback (default: 1, for down command)")
	fmt.Println("  -target string")
	fmt.Println("        Target migration name to rollback to (required for rollback-to command)")
	fmt.Println("  -help")
	fmt.Println("        Show this help message")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  # Create a new migration")
	fmt.Println("  go run cmd/migrate/main.go -command=create -name=\"create_users_table\"")
	fmt.Println("  make migrate-create name=\"create_users_table\"")
	fmt.Println()
	fmt.Println("  # Run migrations")
	fmt.Println("  go run cmd/migrate/main.go -command=up")
	fmt.Println("  make migrate-up")
	fmt.Println()
	fmt.Println("  # Rollback last migration")
	fmt.Println("  go run cmd/migrate/main.go -command=down")
	fmt.Println("  go run cmd/migrate/main.go -command=down -steps=2")
	fmt.Println()
	fmt.Println("  # Rollback to specific migration")
	fmt.Println("  go run cmd/migrate/main.go -command=rollback-to -target=\"20250713063709_create_example_table\"")
	fmt.Println()
	fmt.Println("  # Check migration status")
	fmt.Println("  go run cmd/migrate/main.go -command=status")
	fmt.Println("  make migrate-status")
	fmt.Println()
	fmt.Println("Generated files follow the pattern:")
	fmt.Println("  YYYYMMDDHHMMSS_migration_name.up.sql (forward migration)")
	fmt.Println("  YYYYMMDDHHMMSS_migration_name.down.sql (rollback migration)")
}
