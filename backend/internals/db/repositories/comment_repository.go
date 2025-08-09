package repositories

import (
	"database/sql"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

func (r *Repository) CreateComment(userId, postId, content string, parentId *string) (*model.Comment, error) {
	comment := &model.Comment{
		UserId:   userId,
		PostId:   postId,
		ParentId: parentId,
		Content:  content,
	}

	if userId == "" || postId == "" || content == "" {
		return nil, db.NewValidationError("comment", "user_id, post_id, and content cannot be empty")
	}

	if len(content) > 500 {
		return nil, db.NewValidationError("content", "comment content exceeds maximum length of 500 characters")
	}

	if parentId != nil {
		var parentActualId string
		var parentParentID *string
		err := r.DB.QueryRow("SELECT id, parentid FROM \"Comment\" WHERE id = $1", *parentId).Scan(&parentActualId, &parentParentID)
		if err != nil {
			if err == sql.ErrNoRows {
				return nil, db.NewNotFoundError("comment", *parentId)
			}
			log.Printf("ERROR: failed to query parent comment: %v", err)
			return nil, db.NewDatabaseError("select", "comments", err)
		}
		if parentParentID != nil {
			return nil, db.NewValidationError("parent_id", "Cannot reply to a reply comment")
		}
	}

	err := r.DB.QueryRow(`
		INSERT INTO "Comment" (userid, postid, parentid, content)
		VALUES ($1, $2, $3, $4)
		RETURNING id, createdat, updatedat
	`, userId, postId, parentId, content).Scan(&comment.Id, &comment.CreatedAt, &comment.UpdatedAt)
	if err != nil {
		log.Printf("ERROR: failed to insert comment: %v", err)
		return nil, db.NewDatabaseError("insert", "comments", err)
	}
	return comment, nil
}

func (r *Repository) GetCommentsByPostId(postId string, limit, offset int) ([]model.CommentResponse, error) {
	if postId == "" {
		return nil, db.NewValidationError("post_id", "post_id cannot be empty")
	}

	// Query all comments for the post ordered by creation date
	// We don't apply limit/offset here because we need all comments to build the nested structure
	rows, err := r.DB.Query(`
		SELECT id, userid, postid, parentid, content, createdat, updatedat
		FROM "Comment" 
		WHERE postid = $1
		ORDER BY createdat ASC
	`, postId)
	if err != nil {
		log.Printf("ERROR: failed to query comments: %v", err)
		return nil, db.NewDatabaseError("select", "comments", err)
	}
	defer rows.Close()

	var allComments []model.Comment
	commentMap := make(map[string]*model.Comment)
	replyMap := make(map[string][]model.Comment) // Map parent_id to its replies

	// Read all comments and store them in maps
	for rows.Next() {
		var comment model.Comment
		var parentId sql.NullString

		err := rows.Scan(
			&comment.Id,
			&comment.UserId,
			&comment.PostId,
			&parentId,
			&comment.Content,
			&comment.CreatedAt,
			&comment.UpdatedAt,
		)
		if err != nil {
			log.Printf("ERROR: failed to scan comment: %v", err)
			return nil, db.NewDatabaseError("scan", "comments", err)
		}

		// Handle nullable parent_id
		if parentId.Valid {
			comment.ParentId = &parentId.String
		}

		// Store in map for quick lookup
		commentMap[comment.Id] = &comment
		allComments = append(allComments, comment)

		// Group replies by parent_id
		if comment.ParentId != nil {
			replyMap[*comment.ParentId] = append(replyMap[*comment.ParentId], comment)
		}
	}

	if err = rows.Err(); err != nil {
		log.Printf("ERROR: error iterating over comment rows: %v", err)
		return nil, db.NewDatabaseError("iterate", "comments", err)
	}

	// Build CommentResponse objects for top-level comments
	var commentResponses []model.CommentResponse

	for _, comment := range allComments {
		if comment.ParentId == nil { // Top-level comment
			commentResponse := model.CommentResponse{
				Comment:         comment,
				Replies:         []model.Comment{},
				ReplyCount:      0,
				TotalReplyCount: 0,
			}

			// Get replies for this comment
			if replies, exists := replyMap[comment.Id]; exists {
				commentResponse.TotalReplyCount = len(replies)

				// Only include the latest reply (last one in chronological order)
				if len(replies) > 0 {
					latestReply := replies[len(replies)-1]
					commentResponse.Replies = []model.Comment{latestReply}
					commentResponse.ReplyCount = 1
				}
			}

			commentResponses = append(commentResponses, commentResponse)
		}
	}

	// Apply pagination to top-level comments only
	if offset >= len(commentResponses) {
		return []model.CommentResponse{}, nil
	}

	end := offset + limit
	if end > len(commentResponses) {
		end = len(commentResponses)
	}

	if limit > 0 {
		return commentResponses[offset:end], nil
	}

	return commentResponses, nil
}

func (r *Repository) GetCommentById(commentId string, replyLimit, replyOffset int) (*model.CommentResponse, error) {
	if commentId == "" {
		return nil, db.NewValidationError("comment_id", "comment_id cannot be empty")
	}

	// First, get the main comment
	var comment model.Comment
	var parentId sql.NullString

	err := r.DB.QueryRow(`
		SELECT id, userid, postid, parentid, content, createdat, updatedat
		FROM "Comment" 
		WHERE id = $1
	`, commentId).Scan(
		&comment.Id,
		&comment.UserId,
		&comment.PostId,
		&parentId,
		&comment.Content,
		&comment.CreatedAt,
		&comment.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("comment", commentId)
		}
		log.Printf("ERROR: failed to query comment: %v", err)
		return nil, db.NewDatabaseError("select", "comments", err)
	}

	// Handle nullable parent_id
	if parentId.Valid {
		comment.ParentId = &parentId.String
	}

	// Get total count of replies
	var totalReplyCount int
	err = r.DB.QueryRow(`
		SELECT COUNT(*) 
		FROM "Comment" 
		WHERE parentid = $1
	`, commentId).Scan(&totalReplyCount)
	if err != nil {
		log.Printf("ERROR: failed to count replies: %v", err)
		return nil, db.NewDatabaseError("count", "comments", err)
	}

	// Get paginated replies
	var replies []model.Comment
	if totalReplyCount > 0 {
		rows, err := r.DB.Query(`
			SELECT id, userid, postid, parentid, content, createdat, updatedat
			FROM "Comment" 
			WHERE parentid = $1
			ORDER BY createdat ASC
			LIMIT $2 OFFSET $3
		`, commentId, replyLimit, replyOffset)
		if err != nil {
			log.Printf("ERROR: failed to query replies: %v", err)
			return nil, db.NewDatabaseError("select", "comments", err)
		}
		defer rows.Close()

		for rows.Next() {
			var reply model.Comment
			var replyParentId sql.NullString

			err := rows.Scan(
				&reply.Id,
				&reply.UserId,
				&reply.PostId,
				&replyParentId,
				&reply.Content,
				&reply.CreatedAt,
				&reply.UpdatedAt,
			)
			if err != nil {
				log.Printf("ERROR: failed to scan reply: %v", err)
				return nil, db.NewDatabaseError("scan", "comments", err)
			}

			// Handle nullable parent_id
			if replyParentId.Valid {
				reply.ParentId = &replyParentId.String
			}

			replies = append(replies, reply)
		}

		if err = rows.Err(); err != nil {
			log.Printf("ERROR: error iterating over reply rows: %v", err)
			return nil, db.NewDatabaseError("iterate", "comments", err)
		}
	}

	// Build the CommentResponse
	commentResponse := &model.CommentResponse{
		Comment:         comment,
		Replies:         replies,
		ReplyCount:      len(replies),
		TotalReplyCount: totalReplyCount,
	}

	return commentResponse, nil
}

func (repo *Repository) UpdateComment(id, content string) error {
	if id == "" || content == "" {
		return db.NewValidationError("comment", "id and content cannot be empty")
	}

	tx, err := repo.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "Comment", err)
	}
	defer tx.Rollback()

	res, err := tx.Exec(`UPDATE "Comment" SET content = $1 WHERE id = $2`, content, id)
	if err != nil {
		log.Printf("ERROR: failed to update comment: %v", err)
		return db.NewDatabaseError("update", "Comment", err)
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return db.NewDatabaseError("update", "Comment", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("comment", id)
	}

	err = tx.Commit()
	if err != nil {
		log.Printf("ERROR: failed to commit transaction: %v", err)
		return db.NewDatabaseError("commit", "transaction", err)
	}

	return nil
}

func (r *Repository) DeleteComment(id string) error {
	if id == "" {
		return db.NewValidationError("comment", "id cannot be empty")
	}

	tx, err := r.DB.Begin()
	if err != nil {
		log.Printf("ERROR: failed to begin transaction: %v", err)
		return db.NewDatabaseError("begin_transaction", "Comment", err)
	}
	defer tx.Rollback()

	res, err := tx.Exec(`DELETE FROM "Comment" WHERE id = $1`, id)
	if err != nil {
		log.Printf("ERROR: failed to delete comment: %v", err)
		return db.NewDatabaseError("delete", "Comment", err)
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		log.Printf("ERROR: failed to get rows affected: %v", err)
		return db.NewDatabaseError("delete", "Comment", err)
	}

	if rowsAffected == 0 {
		return db.NewNotFoundError("comment", id)
	}

	err = tx.Commit()
	if err != nil {
		log.Printf("ERROR: failed to commit transaction: %v", err)
		return db.NewDatabaseError("commit", "transaction", err)
	}

	return nil
}