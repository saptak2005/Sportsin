package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"sportsin_backend/internals/chat/redis"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/notifications"
)

// upgrader is used to upgrade the HTTP connection to a WebSocket connection.
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// In production, you MUST implement a proper origin check.
	// For example, check if the request origin is in a list of allowed domains.
	CheckOrigin: func(r *http.Request) bool {
		// os.Getenv("ALLOWED_ORIGIN")
		return true
	},
}

// ChatHandler holds dependencies for handling chat-related requests.
type ChatHandler struct {
	hub        *redis.Hub
	repo       *repositories.Repository
	snsService *notifications.SNSService
}

// NewChatHandler creates a new ChatHandler.
func NewChatHandler(h *redis.Hub, r *repositories.Repository, sns *notifications.SNSService) *ChatHandler {
	return &ChatHandler{
		hub:        h,
		repo:       r,
		snsService: sns,
	}
}

// ServeWs handles WebSocket requests from authenticated users.
func (ch *ChatHandler) ServeWs(c *gin.Context) {
	log.Println("[WS] ServeWs called")
	// Log all context keys for debugging
	for k, v := range c.Keys {
		log.Printf("[WS] Context key: %s, value: %v", k, v)
	}
	userIDStr, exists := c.Get("userID") // FIXED: use correct context key
	log.Printf("[WS] userID: %v, exists: %v", userIDStr, exists)
	if !exists {
		log.Println("[WS] No userID in context, aborting with 401")
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
		return
	}

	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		log.Printf("[WS] Invalid user ID format: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format in token"})
		return
	}

	log.Printf("[WS] Upgrading connection for user: %s", userID)
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection for user %s: %v", userID, err)
		return
	}

	// Create a new client for the hub.
	client := &redis.Client{
		UserID: userID.String(),
		Conn:   conn,
		Send:   make(chan []byte, 256),
		Hub:    ch.hub,
	}
	ch.hub.RegisterClient(client)

	// Set a close handler to perform cleanup when the connection is closed.
	conn.SetCloseHandler(func(code int, text string) error {
		// The unregister is handled in the ReadPump defer block.
		return nil
	})

	// Start the read and write pumps in separate goroutines.
	go client.WritePump()
	go client.ReadPump(ch.repo)
}

// GetChatRooms retrieves all chat rooms for the authenticated user.
func (ch *ChatHandler) GetChatRooms(c *gin.Context) {
	userIDStr, exists := c.Get("userID") // fixed context key
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
		return
	}
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	rooms, err := ch.repo.GetChatRoomsForUser(userID)
	if err != nil {
		log.Printf("Error getting chat rooms for user %s: %v", userID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve chat rooms"})
		return
	}

	c.JSON(http.StatusOK, rooms)
}

// GetMessages retrieves paginated messages for a specific chat room.
func (ch *ChatHandler) GetMessages(c *gin.Context) {
	userIDStr, exists := c.Get("userID") // fixed key from "user_id" to "userID"
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	roomIDStr := c.Param("roomID")
	roomID, err := uuid.Parse(roomIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID"})
		return
	}

	// SECURITY FIX: Check if user is authorized to access this room
	authorized, err := ch.repo.IsUserInChatRoom(roomID, userID)
	if err != nil {
		log.Printf("Error checking room authorization for user %s, room %s: %v", userID, roomID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Authorization check failed"})
		return
	}
	if !authorized {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied to this chat room"})
		return
	}

	// Pagination parameters
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	// Validate pagination parameters
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}

	messages, err := ch.repo.GetMessagesForRoom(roomID, limit, offset)
	if err != nil {
		log.Printf("Error getting messages for room %s: %v", roomID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to retrieve messages"})
		return
	}

	// After fetching, mark these messages as read for the current user.
	// This is an optimistic update; it runs in the background.
	go func() {
		if err := ch.repo.MarkMessagesAsRead(roomID, userID); err != nil {
			log.Printf("Error marking messages as read for user %s in room %s: %v", userID, roomID, err)
		}
	}()

	c.JSON(http.StatusOK, messages)
}

// MarkRoomAsRead handles the request to mark all messages in a room as read.
func (ch *ChatHandler) MarkRoomAsRead(c *gin.Context) {
	userIDStr, exists := c.Get("userID") // fixed key from "user_id" to "userID"
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	roomIDStr := c.Param("roomID")
	roomID, err := uuid.Parse(roomIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid room ID"})
		return
	}

	// SECURITY FIX: Check if user is authorized to access this room
	authorized, err := ch.repo.IsUserInChatRoom(roomID, userID)
	if err != nil {
		log.Printf("Error checking room authorization for user %s, room %s: %v", userID, roomID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Authorization check failed"})
		return
	}
	if !authorized {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied to this chat room"})
		return
	}

	err = ch.repo.MarkMessagesAsRead(roomID, userID)
	if err != nil {
		log.Printf("Error marking messages as read for user %s in room %s: %v", userID, roomID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to mark messages as read"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Messages marked as read"})
}

// SendMessage handles sending a message and notifies the recipient
func (ch *ChatHandler) SendMessage(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
		return
	}
	userID := userIDStr.(string)

	roomIDStr := c.Param("roomID")
	roomID := roomIDStr

	var req struct {
		Message string `json:"message"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	msg, err := ch.repo.CreateMessage(uuid.MustParse(roomID), uuid.MustParse(userID), req.Message)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send message"})
		return
	}

	// Determine recipient
	room, err := ch.repo.FindOrCreateChatRoom(uuid.MustParse(msg.ChatRoomId), uuid.MustParse(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch chat room"})
		return
	}
	var recipientID string
	if room.User1 == userID {
		recipientID = room.User2
	} else {
		recipientID = room.User1
	}

	recipientARN, err := ch.repo.GetUserSnsEndpointArn(uuid.MustParse(recipientID))
	if err == nil && recipientARN != "" {
		notification := notifications.Notification{
			Title: "New Chat Message",
			Body:  req.Message,
			Data: map[string]string{
				"ChatRoomID": msg.ChatRoomId,
				"SenderID":   userID,
			},
			TargetARN: recipientARN,
			Platform:  "android", // or "ios"
			Type:      "chat_message",
		}
		go ch.snsService.Send(notification)
	}

	c.JSON(http.StatusOK, msg)
}
