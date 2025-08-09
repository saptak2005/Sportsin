package model

import "time"

type Post struct {
	AppModel
	UserId    string      `json:"user_id"`
	Content   string      `json:"content"`
	Tags      string      `json:"tags"` // Store as comma-separated string to match DB
	LikeCount int         `json:"like_count"`
	Images    []PostImage `json:"images,omitempty"`
}

type PostWithComment struct {
	Post
	LatestComment *Comment    `json:"latest_comment,omitempty"`
	TotalComments int         `json:"total_comments"`
	UserLiked     bool        `json:"user_liked"`
	Images        []PostImage `json:"images,omitempty"`
}

type PostWithCommentsResponse struct {
	Post
	Comments []CommentResponse `json:"comments,omitempty"`
}

type CreatePostRequest struct {
	Content string   `json:"content" binding:"required"`
	Tags    []string `json:"tags,omitempty"`
}

type UpdatePostRequest struct {
	Content string   `json:"content,omitempty"`
	Tags    []string `json:"tags,omitempty"`
}

type PostResponse struct {
	Id        string      `json:"id"`
	UserId    string      `json:"user_id"`
	Content   string      `json:"content"`
	Tags      []string    `json:"tags"`
	Images    []PostImage `json:"images,omitempty"`
	CreatedAt time.Time   `json:"created_at"`
	UpdatedAt time.Time   `json:"updated_at"`
	Image_url string      `json:"image_url,omitempty"` // Added for image URL in response
	LikeCount int         `json:"like_count"`
}
