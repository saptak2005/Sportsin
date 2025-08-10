package redis

import (
	"context"
	"github.com/redis/go-redis/v9"
	"log"
)

func NewHub(rdb *redis.Client) *Hub {
	return &Hub{
		clients:    make(map[string]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		rdb:        rdb,
		ctx:        context.Background(),
	}
}

func (h *Hub) Run() {
	log.Println("Chat Hub started and running...")
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client.UserID] = client
			h.mu.Unlock()
			log.Printf("Client registered: %s (Total clients: %d)", client.UserID, len(h.clients))
		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client.UserID]; ok {
				delete(h.clients, client.UserID)
				close(client.Send)
				if client.Sub != nil {
					client.Sub.Close()
				}
			}
			h.mu.Unlock()
			log.Printf("Client unregistered: %s (Total clients: %d)", client.UserID, len(h.clients))
		}
	}
}

func (h *Hub) RegisterClient(client *Client) {
	log.Printf("Attempting to register client: %s", client.UserID)
	h.register <- client
}
