package repositories

import (
	"database/sql"
	"log"
	"time"

	"github.com/google/uuid"
	"sportsin_backend/internals/model"
)

// Find or create a chat room between two users
func (r *Repository) FindOrCreateChatRoom(user1ID, user2ID uuid.UUID) (*model.ChatRoom, error) {
	log.Printf("[DEBUG] FindOrCreateChatRoom called with user1ID: %s, user2ID: %s", user1ID, user2ID)
	// Ensure consistent ordering of user IDs
	if user1ID.String() > user2ID.String() {
		user1ID, user2ID = user2ID, user1ID
	}
	log.Printf("[DEBUG] Ordered user IDs: user1ID: %s, user2ID: %s", user1ID, user2ID)

	room := &model.ChatRoom{}
	var lastMessageAt sql.NullString
	query := `SELECT id, user1, user2, created_at, last_message_at FROM "ChatRoom" WHERE user1 = $1 AND user2 = $2`
	row := r.DB.QueryRow(query, user1ID, user2ID)
	err := row.Scan(&room.Id, &room.User1, &room.User2, &room.CreatedAt, &lastMessageAt)
	room.LastMessageAt = lastMessageAt

	if err == sql.ErrNoRows {
		roomID := uuid.New().String()
		constraintKey := user1ID.String() + ":" + user2ID.String()
		log.Printf("[DEBUG] Creating new chat room with id: %s for users %s and %s, constraint_key: %s", roomID, user1ID, user2ID, constraintKey)
		var lastMessageAt sql.NullString
		insertQuery := `INSERT INTO "ChatRoom" (id, user1, user2, created_at, constraint_user1_user2) VALUES ($1, $2, $3, $4, $5) RETURNING id, user1, user2, created_at, last_message_at`
		err = r.DB.QueryRow(insertQuery, roomID, user1ID, user2ID, time.Now().UTC(), constraintKey).Scan(&room.Id, &room.User1, &room.User2, &room.CreatedAt, &lastMessageAt)
		room.LastMessageAt = lastMessageAt
		if err != nil {
			log.Printf("[ERROR] Error creating chat room for users %s and %s: %v", user1ID, user2ID, err)
			return nil, err
		}
		return room, nil
	} else if err != nil {
		log.Printf("[ERROR] Error finding chat room for users %s and %s: %v", user1ID, user2ID, err)
		return nil, err
	}

	log.Printf("[DEBUG] Found existing chat room: %+v", room)
	return room, nil
}

// Create a chat message in a chat room
func (r *Repository) CreateMessage(roomID, senderID uuid.UUID, content string) (*model.ChatMessage, error) {
	tx, err := r.DB.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	msg := &model.ChatMessage{}
	sentAt := time.Now().UTC()
	msgID := uuid.New().String()

	msgQuery := `INSERT INTO "Messages" (id, chat_room_id, sent_from, content, sent_at) VALUES ($1, $2, $3, $4, $5) RETURNING id, chat_room_id, sent_from, content, sent_at, read_status`
	err = tx.QueryRow(msgQuery, msgID, roomID, senderID, content, sentAt).Scan(&msg.Id, &msg.ChatRoomId, &msg.SenderId, &msg.Message, &msg.CreatedAt, &msg.Read)
	if err != nil {
		log.Printf("Error creating message in room %s: %v", roomID, err)
		return nil, err
	}

	updateQuery := `UPDATE "ChatRoom" SET last_message_at = $1 WHERE id = $2`
	_, err = tx.Exec(updateQuery, sentAt, roomID)
	if err != nil {
		log.Printf("Error updating last_message_at for room %s: %v", roomID, err)
		return nil, err
	}

	return msg, tx.Commit()
}

// GetMessagesForRoom returns messages for a chat room
func (r *Repository) GetMessagesForRoom(roomID uuid.UUID, limit, offset int) ([]model.ChatMessage, error) {
	query := `SELECT id, chat_room_id, sent_from, content, sent_at, read_status FROM "Messages" WHERE chat_room_id = $1 ORDER BY sent_at ASC LIMIT $2 OFFSET $3`
	rows, err := r.DB.Query(query, roomID, limit, offset)
	if err != nil {
		log.Printf("Error getting messages for room %s: %v", roomID, err)
		return nil, err
	}
	defer rows.Close()

	var messages []model.ChatMessage
	for rows.Next() {
		var msg model.ChatMessage
		var readStatus bool
		err := rows.Scan(&msg.Id, &msg.ChatRoomId, &msg.SenderId, &msg.Message, &msg.CreatedAt, &readStatus)
		if err != nil {
			log.Printf("Error scanning message row: %v", err)
			continue
		}
		msg.Read = readStatus
		messages = append(messages, msg)
	}
	return messages, nil
}

// MarkMessagesAsRead marks all unread messages sent by another user in a room as read
func (r *Repository) MarkMessagesAsRead(roomID, readerID uuid.UUID) error {
	query := `UPDATE "Messages" SET read_status = TRUE WHERE chat_room_id = $1 AND sent_from != $2 AND read_status = FALSE`
	_, err := r.DB.Exec(query, roomID, readerID)
	if err != nil {
		log.Printf("Error marking messages as read in room %s for user %s: %v", roomID, readerID, err)
	}
	return err
}

// GetChatRoomsForUser returns all chat rooms for a given user
func (r *Repository) GetChatRoomsForUser(userID uuid.UUID) ([]model.ChatRoom, error) {
	query := `SELECT id, user1, user2, created_at, last_message_at FROM "ChatRoom" WHERE user1 = $1 OR user2 = $1 ORDER BY last_message_at DESC, created_at DESC`
	rows, err := r.DB.Query(query, userID)
	if err != nil {
		log.Printf("Error getting chat rooms for user %s: %v", userID, err)
		return nil, err
	}
	defer rows.Close()

	var rooms []model.ChatRoom
	for rows.Next() {
		var room model.ChatRoom
		err := rows.Scan(&room.Id, &room.User1, &room.User2, &room.CreatedAt, &room.LastMessageAt)
		if err != nil {
			log.Printf("Error scanning chat room row: %v", err)
			continue
		}
		rooms = append(rooms, room)
	}
	return rooms, nil
}

// ADDITIONAL FIX: Add authorization check
func (r *Repository) IsUserInChatRoom(roomID, userID uuid.UUID) (bool, error) {
	query := `SELECT 1 FROM "ChatRoom" WHERE id = $1 AND (user1 = $2 OR user2 = $2)`
	var exists int
	err := r.DB.QueryRow(query, roomID, userID).Scan(&exists)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// GetUserSnsEndpointArn returns the SNS endpoint ARN for a user
func (r *Repository) GetUserSnsEndpointArn(userID uuid.UUID) (string, error) {
	var arn string
	query := `SELECT sns_endpoint_arn FROM "User" WHERE id = $1`
	err := r.DB.QueryRow(query, userID).Scan(&arn)
	if err != nil {
		return "", err
	}
	return arn, nil
}
