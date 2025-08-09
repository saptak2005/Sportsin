package model

import "time"

// PostLike represents a like on a post by a user.
// It corresponds to the "post_likes" table.
type PostLike struct {
	PostID    string    `json:"post_id"`
	UserID    string    `json:"user_id"`
	CreatedAt time.Time `json:"created_at"`
}
