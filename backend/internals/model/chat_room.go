package model

import "database/sql"

type ChatRoom struct {
	AppModel
	User1         string         `json:"user_1"`          // User ID of the first user in the chat room
	User2         string         `json:"user_2"`          // User ID of the second user in the chat room
	LastMessageAt sql.NullString `json:"last_message_at"` // Timestamp of the last message in the chat room
}
