package db

// import (
// 	"database/sql"
// 	"log"
// )

// func RunMigrationsOld(db *sql.DB) {
// 	// Create User table with only essential fields
// 	userTable := `CREATE TABLE IF NOT EXISTS "User"(
// 		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
// 		username VARCHAR(255) NOT NULL UNIQUE,
// 		email VARCHAR(255) NOT NULL UNIQUE,
// 		role VARCHAR(255) NOT NULL,
// 		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
// 		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
// 	)`

// 	_, err := db.Exec(userTable)
// 	if err != nil {
// 		log.Fatal("Failed to create user table:", err)
// 	}
// 	log.Println("✅ User table created successfully")

// 	// Create UserDetails table
// 	userDetailsTable := `CREATE TABLE IF NOT EXISTS "UserDetails"(
// 		id UUID PRIMARY KEY,
// 		username VARCHAR(255) NOT NULL UNIQUE,
// 		profile_pic VARCHAR(255),
// 		name VARCHAR(255),
// 		middlename VARCHAR(255),
// 		surname VARCHAR(255),
// 		dob DATE,
// 		gender VARCHAR(255),
// 		about TEXT,
// 		FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(userDetailsTable)
// 	if err != nil {
// 		log.Fatal("Failed to create UserDetails table:", err)
// 	}
// 	log.Println("✅ UserDetails table created successfully")

// 	// Create Address table
// 	addressTable := `CREATE TABLE IF NOT EXISTS "Address"(
// 		id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
// 		user_id UUID NOT NULL,
// 		country VARCHAR(100) NOT NULL,
// 		state VARCHAR(100) NOT NULL,
// 		city VARCHAR(100) NOT NULL,
// 		street VARCHAR(255) NOT NULL,
// 		building VARCHAR(100) NOT NULL,
// 		pincode VARCHAR(20) NOT NULL,
// 		FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(addressTable)
// 	if err != nil {
// 		log.Fatal("Failed to create Address table:", err)
// 	}
// 	log.Println("✅ Address table created successfully")

// 	// Removed About, User_id
// 	// Added Foreign Key to User
// 	playerTable := `CREATE TABLE IF NOT EXISTS "Player" (
// 		id UUID PRIMARY KEY,
// 		level VARCHAR(50) NOT NULL,
// 		interest VARCHAR(500) NOT NULL,
// 		interest_country VARCHAR(100),
// 		FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(playerTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for playerTable:", err)
// 	}

// 	recruiterTable := `CREATE TABLE IF NOT EXISTS "Recruiter" (
// 		id UUID PRIMARY KEY,
// 		organization_name VARCHAR(255) NOT NULL,
// 		organization_id VARCHAR(100) NOT NULL,
// 		phone_no VARCHAR(20) NOT NULL,
// 		position VARCHAR(255),
// 		FOREIGN KEY (id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(recruiterTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for recruiterTable:", err)
// 	}

// 	userSkillTable := `CREATE TABLE IF NOT EXISTS "UserSkill" (
// 		id UUID PRIMARY KEY,
// 		user_id UUID NOT NULL,
// 		sport_id UUID NOT NULL,
// 		FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(userSkillTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for userSkillTable:", err)
// 	}

// 	sportsTable := `CREATE TABLE IF NOT EXISTS "Sports" (
// 		id UUID PRIMARY KEY,
// 		name VARCHAR(255) NOT NULL,
// 		description TEXT
// 	)`
// 	_, err = db.Exec(sportsTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for sportsTable:", err)
// 	}

// 	achievementsTable := `CREATE TABLE IF NOT EXISTS "Achievements" (
// 		id UUID PRIMARY KEY,
// 		user_id UUID NOT NULL,
// 		date DATE NOT NULL,
// 		sport_id UUID NOT NULL,
// 		tournament_title VARCHAR(255) NOT NULL,
// 		description TEXT,
// 		level VARCHAR(50) NOT NULL,
// 		stats JSONB,
// 		certificate_link VARCHAR(500),
// 		FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
// 		FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(achievementsTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for achievementsTable:", err)
// 	}

// 	tournamentTable := `CREATE TABLE IF NOT EXISTS "Tournament" (
// 		id UUID PRIMARY KEY,
// 		host_id UUID NOT NULL,
// 		name VARCHAR(255) NOT NULL,
// 		description TEXT,
// 		location VARCHAR(255) NOT NULL,
// 		sport_id UUID NOT NULL,
// 		min_age INT NOT NULL,
// 		max_age INT NOT NULL,
// 		level VARCHAR(50) NOT NULL,
// 		level_location VARCHAR(255) NOT NULL,
// 		gender VARCHAR(20) NOT NULL,
// 		country_restriction VARCHAR(100),
// 		status VARCHAR(50) NOT NULL DEFAULT 'ongoing',
// 		banner_link VARCHAR(500),
// 		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
// 		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
// 		FOREIGN KEY (host_id) REFERENCES "User"(id) ON DELETE CASCADE,
// 		FOREIGN KEY (sport_id) REFERENCES "Sports"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(tournamentTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for tournamentTable:", err)
// 	}

// 	tournamentParticipantTable := `CREATE TABLE IF NOT EXISTS "TournamentParticipant" (
// 		id UUID PRIMARY KEY,
// 		user_id UUID NOT NULL,
// 		tournament_id UUID NOT NULL,
// 		status VARCHAR(20) NOT NULL DEFAULT 'pending',
// 		registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
// 		FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE,
// 		FOREIGN KEY (tournament_id) REFERENCES "Tournament"(id) ON DELETE CASCADE,
// 		UNIQUE(user_id, tournament_id)
// 	)`
// 	_, err = db.Exec(tournamentParticipantTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for tournamentParticipantTable:", err)
// 	}

// 	tournamentImagesTable := `CREATE TABLE IF NOT EXISTS "TournamentImages" (
// 		id UUID PRIMARY KEY,
// 		tournament_id UUID NOT NULL,
// 		image_url VARCHAR(500) NOT NULL,
// 		FOREIGN KEY (tournament_id) REFERENCES "Tournament"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(tournamentImagesTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for tournamentImagesTable:", err)
// 	}

// 	postTable := `CREATE TABLE IF NOT EXISTS "Post" (
// 		id UUID PRIMARY KEY,
// 		user_id UUID NOT NULL,
// 		created_at DATE NOT NULL,
// 		updated_at DATE NOT NULL,
// 		content TEXT NOT NULL,
// 		tags TEXT,
// 		FOREIGN KEY (user_id) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(postTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for postTable:", err)
// 	}

// 	postImagesTable := `CREATE TABLE IF NOT EXISTS "PostImages" (
// 		id UUID PRIMARY KEY,
// 		post_id UUID NOT NULL,
// 		image_url VARCHAR(500) NOT NULL,
// 		FOREIGN KEY (post_id) REFERENCES "Post"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(postImagesTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for postImagesTable:", err)
// 	}

// 	chatRoomTable := `CREATE TABLE IF NOT EXISTS "ChatRoom" (
// 		id UUID PRIMARY KEY,
// 		user1 UUID NOT NULL,
// 		user2 UUID NOT NULL,
// 		created_at DATE NOT NULL,
// 		last_message_at DATE,
// 		constraint_user1_user2 VARCHAR(255) NOT NULL,
// 		FOREIGN KEY (user1) REFERENCES "User"(id) ON DELETE CASCADE,
// 		FOREIGN KEY (user2) REFERENCES "User"(id) ON DELETE CASCADE,
// 		UNIQUE(user1, user2)
// 	)`
// 	_, err = db.Exec(chatRoomTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for chatRoomTable:", err)
// 	}

// 	messagesTable := `CREATE TABLE IF NOT EXISTS "Messages" (
// 		id UUID PRIMARY KEY,
// 		chat_room_id UUID NOT NULL,
// 		sent_from UUID NOT NULL,
// 		sent_at DATE NOT NULL,
// 		read_status BOOLEAN NOT NULL DEFAULT FALSE,
// 		content TEXT NOT NULL,
// 		FOREIGN KEY (chat_room_id) REFERENCES "ChatRoom"(id) ON DELETE CASCADE,
// 		FOREIGN KEY (sent_from) REFERENCES "User"(id) ON DELETE CASCADE
// 	)`
// 	_, err = db.Exec(messagesTable)
// 	if err != nil {
// 		log.Fatal("Failed to run migrations for messagesTable:", err)
// 	}

// 	userAddressFK := `
// 	DO $$
// 	BEGIN
// 		IF NOT EXISTS (
// 			SELECT 1 FROM information_schema.table_constraints
// 			WHERE constraint_name = 'user_address_id_fkey'
// 		) THEN
// 			ALTER TABLE "User" ADD CONSTRAINT user_address_id_fkey FOREIGN KEY (address_id) REFERENCES "Address"(id);
// 		END IF;
// 	END$$;
// 	`
// 	_, err = db.Exec(userAddressFK)
// 	if err != nil {
// 		log.Println("User -> Address foreign key constraint may already exist:", err)
// 	}

// 	userSkillSportsFK := `
// 	DO $$
// 	BEGIN
// 		IF NOT EXISTS (
// 			SELECT 1 FROM information_schema.table_constraints
// 			WHERE constraint_name = 'userskill_sport_id_fkey'
// 		) THEN
// 			ALTER TABLE "UserSkill" ADD CONSTRAINT userskill_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES "Sports"(id);
// 		END IF;
// 	END$$;
// 	`
// 	_, err = db.Exec(userSkillSportsFK)
// 	if err != nil {
// 		log.Println("UserSkill->Sports foreign key constraint may already exist:", err)
// 	}

// 	log.Println("All database migrations completed successfully!")
// }
