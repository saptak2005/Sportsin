package model

type Comment struct {
	Id        string  `json:"id"`
	UserId    string  `json:"user_id"`
	PostId    string  `json:"post_id"`
	ParentId  *string `json:"parent_id,omitempty"`
	Content   string  `json:"content"`
	CreatedAt string  `json:"created_at"`
	UpdatedAt string  `json:"updated_at"`
}

type CommentResponse struct {
	Comment         Comment   `json:"comment"`
	Replies         []Comment `json:"replies,omitempty"`
	ReplyCount      int       `json:"reply_count"`
	TotalReplyCount int       `json:"total_reply_count"`
}

type CreateCommentRequest struct {
	PostId   string  `json:"post_id" binding:"required"`
	Content  string  `json:"content" binding:"required"`
	ParentId *string `json:"parent_id,omitempty"`
}

type UpdateCommentRequest struct {
	Content string `json:"content" binding:"required"`
}
