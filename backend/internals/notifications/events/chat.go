package event

import (
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/notifications"
)

// ChatMessageEvent represents the data needed to send a chat message notification
// This can be extended for other event types as needed
type ChatMessageEvent struct {
	RecipientARN string
	ChatRoomID   string
	SenderID     string
	Message      string
	Platform     string // "android" or "ios"
}

// SendChatMessageNotification triggers a push notification for a chat message to a user
func SendChatMessageNotification(snsService *notifications.SNSService, event ChatMessageEvent) error {
	notification := notifications.Notification{
		Title:     "New Chat Message",
		Body:      event.Message,
		TargetARN: event.RecipientARN,
		Platform:  event.Platform,
		Type:      "chat",
		Data: map[string]string{
			"chat_room_id": event.ChatRoomID,
			"sender_id":    event.SenderID,
		},
	}
	return snsService.Send(notification)
}

// SendChatMessageToTopic broadcasts a chat message notification to all subscribers of the topic
func SendChatMessageToTopic(snsService *notifications.SNSService, cfg *config.Config, event ChatMessageEvent) error {
	notification := notifications.Notification{
		Title:    "New Chat Message",
		Body:     event.Message,
		Platform: event.Platform,
		Type:     "chat",
		Data: map[string]string{
			"chat_room_id": event.ChatRoomID,
			"sender_id":    event.SenderID,
		},
	}
	return snsService.SendToTopic(notification, cfg.AWS_TOPIC_ARN)
}
