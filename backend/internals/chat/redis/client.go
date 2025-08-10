package redis

import (
	"encoding/json"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"sportsin_backend/internals/db/repositories"
)

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second
	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second
	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10
)

// IncomingChatMessage defines the structure for messages received from the client.
type IncomingChatMessage struct {
	RecipientID string `json:"recipient_id"`
	Content     string `json:"content"`
}

// OutgoingChatMessage defines the structure for messages sent to the client.
type OutgoingChatMessage struct {
	MessageID  string `json:"message_id"`
	SenderID   string `json:"sender_id"`
	Content    string `json:"content"`
	SentAt     string `json:"sent_at"`
	ChatRoomID string `json:"chat_room_id"`
}

// ReadPump pumps messages from the websocket connection to the hub.
func (c *Client) ReadPump(repo *repositories.Repository) {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()
	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error { c.Conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		var msg IncomingChatMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("Error decoding incoming message: %v", err)
			continue
		}

		senderID, _ := uuid.Parse(c.UserID)
		recipientID, _ := uuid.Parse(msg.RecipientID)

		// Find or create a chat room
		room, err := repo.FindOrCreateChatRoom(senderID, recipientID)
		if err != nil {
			log.Printf("Could not find or create chat room: %v", err)
			continue
		}

		// Save the message to the database
		dbMsg, err := repo.CreateMessage(uuid.MustParse(room.Id), senderID, msg.Content)
		if err != nil {
			log.Printf("Failed to save message to database: %v", err)
			continue
		}

		// Prepare the outgoing message payload
		outgoingMsg := OutgoingChatMessage{
			MessageID:  dbMsg.Id,
			SenderID:   c.UserID,
			Content:    dbMsg.Message,
			SentAt:     dbMsg.CreatedAt,
			ChatRoomID: dbMsg.ChatRoomId,
		}

		payload, err := json.Marshal(outgoingMsg)
		if err != nil {
			log.Printf("Error encoding outgoing message: %v", err)
			continue
		}

		// Publish to the recipient's channel
		c.Hub.PublishToUser(msg.RecipientID, payload)
		// Also send the message back to the sender so their UI updates
		c.Hub.PublishToUser(c.UserID, payload)
	}
}

// WritePump pumps messages from the hub to the websocket connection.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()
	// Start listening to Redis Pub/Sub in a separate goroutine
	go c.listenToRedis()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// The hub closed the channel.
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			if err := w.Close(); err != nil {
				return
			}
		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
