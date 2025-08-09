package model

type ChatMessage struct {
	AppModel
	ChatRoomId string `json:"chat_room_id"`
	SenderId   string `json:"sender_id"`
	Read       bool   `json:"read"`
	Message    string `json:"message"`
}
