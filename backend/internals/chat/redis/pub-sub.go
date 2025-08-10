package redis

import (
	"fmt"
	"log"
)

func (h *Hub) PublishToUser(userID string, message []byte) {
	channel := h.userChannel(userID)
	log.Printf("Publishing message to user %s on channel %s", userID, channel)
	err := h.rdb.Publish(h.ctx, channel, message).Err()
	if err != nil {
		log.Printf("Error publishing message to user %s on channel %s: %v", userID, channel, err)
	} else {
		log.Printf("Successfully published message to user %s", userID)
	}
}

// userChannel generates the Redis channel name for a specific user.
func (h *Hub) userChannel(userID string) string {
	return fmt.Sprintf("user:%s", userID)
}

// listenToRedis creates a subscription to the user's channel and forwards messages.
// This is now started per-client.
func (c *Client) listenToRedis() {
	channel := c.Hub.userChannel(c.UserID)
	log.Printf("Starting Redis subscription for user %s on channel %s", c.UserID, channel)

	c.Sub = c.Hub.rdb.Subscribe(c.Hub.ctx, channel)
	defer func() {
		log.Printf("Closing Redis subscription for user %s", c.UserID)
		c.Sub.Close()
	}()

	ch := c.Sub.Channel()
	log.Printf("Redis subscription active for user %s", c.UserID)

	for msg := range ch {
		log.Printf("Received message from Redis for user %s: %s", c.UserID, msg.Payload)
		// Forward message directly to the client's send channel
		select {
		case c.Send <- []byte(msg.Payload):
			log.Printf("Message forwarded to send channel for user %s", c.UserID)
		default:
			log.Printf("Send channel full for user %s, dropping message", c.UserID)
		}
	}
}
