package redis

import (
	"context"
	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
	"sync"
)

type Client struct {
	UserID string
	Conn   *websocket.Conn
	Send   chan []byte
	Hub    *Hub
	Sub    *redis.PubSub
}

type Hub struct {
	clients    map[string]*Client
	mu         sync.RWMutex
	register   chan *Client
	unregister chan *Client
	rdb        *redis.Client
	ctx        context.Context
}
