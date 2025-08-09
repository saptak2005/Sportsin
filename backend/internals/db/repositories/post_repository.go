package repositories

import (
	"database/sql"
	"encoding/json"
	"log"
	"strings"
	"time"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// CreatePost creates a new post in the database
func (repo *Repository) CreatePost(post *model.Post) error {
	if post == nil {
		return db.NewValidationError("post", "post cannot be nil")
	}

	if post.UserId == "" {
		return db.ErrUserIDMissing
	}

	if strings.TrimSpace(post.Content) == "" {
		return db.ErrContentEmpty
	}

	query := `INSERT INTO "Post" (id, user_id, created_at, updated_at, content, tags)
			  VALUES (gen_random_uuid(), $1, $2, $3, $4, $5)
			  RETURNING id, created_at, updated_at`

	now := time.Now()
	err := repo.DB.QueryRow(query, post.UserId, now, now, post.Content, post.Tags).Scan(
		&post.Id, &post.CreatedAt, &post.UpdatedAt)

	if err != nil {
		if strings.Contains(err.Error(), "foreign key constraint") {
			return db.ErrUserNotFound
		}
		if strings.Contains(err.Error(), "duplicate key") {
			return db.ErrPostAlreadyExists
		}
		// Log serious database errors
		log.Printf("Critical error creating post for user %s: %v", post.UserId, err)
		return db.NewDatabaseError("insert", "Post", err)
	}

	return nil
}

// GetPostById retrieves a post by its ID with images
func (repo *Repository) GetPostById(postId string) (*model.Post, error) {
	if postId == "" {
		return nil, db.NewValidationError("post_id", "post ID is required")
	}

	var post model.Post
	query := `
		SELECT 
			p.id, p.user_id, p.created_at, p.updated_at, p.content, 
			COALESCE(p.tags, '') as tags, COALESCE(p.like_count, 0) as like_count,
			COALESCE(
				array_agg(
					CASE WHEN pi.id IS NOT NULL 
					THEN json_build_object('id', pi.id, 'post_id', pi.post_id, 'image_url', pi.image_url)
					END
				) FILTER (WHERE pi.id IS NOT NULL), 
				'{}'
			) as images
		FROM "Post" p
		LEFT JOIN "PostImages" pi ON p.id = pi.post_id
		WHERE p.id = $1
		GROUP BY p.id, p.user_id, p.created_at, p.updated_at, p.content, p.tags, p.like_count`

	var imagesJSON string
	err := repo.DB.QueryRow(query, postId).Scan(
		&post.Id, &post.UserId, &post.CreatedAt, &post.UpdatedAt,
		&post.Content, &post.Tags, &post.LikeCount, &imagesJSON)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, db.NewNotFoundError("post", postId)
		}
		log.Printf("Critical error getting post by ID %s: %v", postId, err)
		return nil, db.NewDatabaseError("select", "Post", err)
	}

	// Parse images JSON
	var images []model.PostImage
	if imagesJSON != "{}" && imagesJSON != "" {
		err = json.Unmarshal([]byte(imagesJSON), &images)
		if err != nil {
			log.Printf("Error unmarshaling images JSON for post %s: %v", postId, err)
			images = []model.PostImage{} // fallback to empty slice
		}
	}
	post.Images = images

	return &post, nil
}

// GetPostsByUserId retrieves all posts by a specific user with images
func (repo *Repository) GetPostsByUserId(userId string, limit, offset int) ([]model.Post, error) {
	if userId == "" {
		return nil, db.ErrUserIDMissing
	}
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	var posts []model.Post
	query := `
		SELECT 
			p.id, p.user_id, p.created_at, p.updated_at, p.content, 
			COALESCE(p.tags, '') as tags, COALESCE(p.like_count, 0) as like_count,
			COALESCE(
				array_agg(
					CASE WHEN pi.id IS NOT NULL 
					THEN json_build_object('id', pi.id, 'post_id', pi.post_id, 'image_url', pi.image_url)
					END
				) FILTER (WHERE pi.id IS NOT NULL), 
				'{}'
			) as images
		FROM "Post" p
		LEFT JOIN "PostImages" pi ON p.id = pi.post_id
		WHERE p.user_id = $1
		GROUP BY p.id, p.user_id, p.created_at, p.updated_at, p.content, p.tags, p.like_count
		ORDER BY p.created_at DESC 
		LIMIT $2 OFFSET $3`

	rows, err := repo.DB.Query(query, userId, limit, offset)
	if err != nil {
		log.Printf("Critical error getting posts by user ID %s: %v", userId, err)
		return nil, db.NewDatabaseError("select", "Post", err)
	}
	defer rows.Close()

	for rows.Next() {
		var post model.Post
		var imagesJSON string

		err := rows.Scan(
			&post.Id, &post.UserId, &post.CreatedAt, &post.UpdatedAt,
			&post.Content, &post.Tags, &post.LikeCount, &imagesJSON)
		if err != nil {
			log.Printf("Critical error scanning post data: %v", err)
			continue
		}

		// Parse images JSON
		var images []model.PostImage
		if imagesJSON != "{}" && imagesJSON != "" {
			err = json.Unmarshal([]byte(imagesJSON), &images)
			if err != nil {
				log.Printf("Error unmarshaling images JSON for post %s: %v", post.Id, err)
				images = []model.PostImage{} // fallback to empty slice
			}
		}
		post.Images = images

		posts = append(posts, post)
	}

	return posts, nil
}

// GetAllPosts retrieves all posts with pagination and images
func (repo *Repository) GetAllPosts(limit, offset int) ([]model.Post, error) {
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	var posts []model.Post
	query := `
		SELECT 
			p.id, p.user_id, p.created_at, p.updated_at, p.content, 
			COALESCE(p.tags, '') as tags, COALESCE(p.like_count, 0) as like_count,
			COALESCE(
				array_agg(
					CASE WHEN pi.id IS NOT NULL 
					THEN json_build_object('id', pi.id, 'post_id', pi.post_id, 'image_url', pi.image_url)
					END
				) FILTER (WHERE pi.id IS NOT NULL), 
				'{}'
			) as images
		FROM "Post" p
		LEFT JOIN "PostImages" pi ON p.id = pi.post_id
		GROUP BY p.id, p.user_id, p.created_at, p.updated_at, p.content, p.tags, p.like_count
		ORDER BY p.created_at DESC 
		LIMIT $1 OFFSET $2`

	rows, err := repo.DB.Query(query, limit, offset)
	if err != nil {
		log.Printf("Critical error getting all posts: %v", err)
		return nil, db.NewDatabaseError("select", "Post", err)
	}
	defer rows.Close()

	for rows.Next() {
		var post model.Post
		var imagesJSON string

		err := rows.Scan(
			&post.Id, &post.UserId, &post.CreatedAt, &post.UpdatedAt,
			&post.Content, &post.Tags, &post.LikeCount, &imagesJSON)
		if err != nil {
			log.Printf("Critical error scanning post data: %v", err)
			continue
		}

		// Parse images JSON
		var images []model.PostImage
		if imagesJSON != "{}" && imagesJSON != "" {
			err = json.Unmarshal([]byte(imagesJSON), &images)
			if err != nil {
				log.Printf("Error unmarshaling images JSON for post %s: %v", post.Id, err)
				images = []model.PostImage{} // fallback to empty slice
			}
		}
		post.Images = images

		posts = append(posts, post)
	}

	return posts, nil
}

// UpdatePost updates a post in the database
func (repo *Repository) UpdatePost(post *model.Post) error {
	if post == nil {
		return db.NewValidationError("post", "post cannot be nil")
	}
	if post.Id == "" {
		return db.NewValidationError("post_id", "post ID is required")
	}
	if post.UserId == "" {
		return db.ErrUserIDMissing
	}
	if strings.TrimSpace(post.Content) == "" {
		return db.ErrContentEmpty
	}

	query := `UPDATE "Post" SET content = $1, tags = $2, updated_at = $3 
			  WHERE id = $4 AND user_id = $5
			  RETURNING updated_at`

	now := time.Now()
	err := repo.DB.QueryRow(query, post.Content, post.Tags, now, post.Id, post.UserId).Scan(&post.UpdatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			return db.NewAuthorizationError("update", "post", post.UserId)
		}
		log.Printf("Critical error updating post %s: %v", post.Id, err)
		return db.NewDatabaseError("update", "Post", err)
	}

	return nil
}

// DeletePost deletes a post from the database
func (repo *Repository) DeletePost(postId, userId string) error {
	if postId == "" {
		return db.NewValidationError("post_id", "post ID is required")
	}
	if userId == "" {
		return db.ErrUserIDMissing
	}

	query := `DELETE FROM "Post" WHERE id = $1 AND user_id = $2`

	result, err := repo.DB.Exec(query, postId, userId)
	if err != nil {
		log.Printf("Critical error deleting post %s: %v", postId, err)
		return db.NewDatabaseError("delete", "Post", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("Critical error getting rows affected for post deletion %s: %v", postId, err)
		return db.NewDatabaseError("delete", "Post", err)
	}

	if rowsAffected == 0 {
		return db.NewAuthorizationError("delete", "post", userId)
	}

	return nil
}

// CheckPostOwnership verifies if a user owns a specific post
func (repo *Repository) CheckPostOwnership(postId, userId string) (bool, error) {
	if postId == "" {
		return false, db.NewValidationError("post_id", "post ID is required")
	}
	if userId == "" {
		return false, db.ErrUserIDMissing
	}

	var count int
	query := `SELECT COUNT(*) FROM "Post" WHERE id = $1 AND user_id = $2`

	err := repo.DB.QueryRow(query, postId, userId).Scan(&count)
	if err != nil {
		log.Printf("Critical error checking post ownership for post %s: %v", postId, err)
		return false, db.NewDatabaseError("select", "Post", err)
	}

	return count > 0, nil
}

// GetAllPostsWithComments returns all posts with their latest comment and total comment count
func (repo *Repository) GetAllPostsWithComments(limit, offset int, userId string) ([]model.PostWithComment, error) {
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	var postsWithComments []model.PostWithComment
	query := `
		SELECT 
			p.id, p.user_id, p.created_at, p.updated_at, p.content, 
			COALESCE(p.tags, '') as tags, COALESCE(p.like_count, 0) as like_count,
			COALESCE(
				json_agg(
					json_build_object('id', pi.id, 'post_id', pi.post_id, 'image_url', pi.image_url)
				) FILTER (WHERE pi.id IS NOT NULL), 
				'[]'
			) as images,
			-- Latest comment subquery
			lc.id as latest_comment_id,
			lc.userid as latest_comment_user_id,
			lc.postid as latest_comment_post_id,
			lc.parentid as latest_comment_parent_id,
			lc.content as latest_comment_content,
			lc.createdat as latest_comment_created_at,
			lc.updatedat as latest_comment_updated_at,
			-- Total comment count
			COALESCE(cc.total_comments, 0) as total_comments,
			-- Check if user liked this post
			CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as user_liked
		FROM "Post" p
		LEFT JOIN "PostImages" pi ON p.id = pi.post_id
		LEFT JOIN LATERAL (
			SELECT id, userid, postid, parentid, content, createdat, updatedat
			FROM "Comment" c
			WHERE c.postid = p.id AND c.parentid IS NULL
			ORDER BY c.createdat DESC
			LIMIT 1
		) lc ON true
		LEFT JOIN (
			SELECT postid, COUNT(*) as total_comments
			FROM "Comment"
			GROUP BY postid
		) cc ON cc.postid = p.id
		LEFT JOIN "post_likes" pl ON p.id = pl.post_id AND pl.user_id = $3
		GROUP BY p.id, p.user_id, p.created_at, p.updated_at, p.content, p.tags, p.like_count,
				 lc.id, lc.userid, lc.postid, lc.parentid, lc.content, lc.createdat, lc.updatedat,
				 cc.total_comments, pl.user_id
		ORDER BY p.created_at DESC 
		LIMIT $1 OFFSET $2`

	rows, err := repo.DB.Query(query, limit, offset, userId)
	if err != nil {
		log.Printf("Critical error getting all posts with comments: %v", err)
		return nil, db.NewDatabaseError("select", "Post", err)
	}
	defer rows.Close()

	for rows.Next() {
		var postWithComment model.PostWithComment
		var imagesJSON string
		var latestCommentID, latestCommentUserID, latestCommentPostID sql.NullString
		var latestCommentParentID sql.NullString
		var latestCommentContent, latestCommentCreatedAt, latestCommentUpdatedAt sql.NullString

		err := rows.Scan(
			&postWithComment.Id, &postWithComment.UserId, &postWithComment.CreatedAt, &postWithComment.UpdatedAt,
			&postWithComment.Content, &postWithComment.Tags, &postWithComment.LikeCount, &imagesJSON,
			&latestCommentID, &latestCommentUserID, &latestCommentPostID, &latestCommentParentID,
			&latestCommentContent, &latestCommentCreatedAt, &latestCommentUpdatedAt,
			&postWithComment.TotalComments, &postWithComment.UserLiked)
		if err != nil {
			log.Printf("Critical error scanning post with comment data: %v", err)
			continue
		}

		// Parse images JSON
		var images []model.PostImage
		if imagesJSON != "[]" && imagesJSON != "" {
			err = json.Unmarshal([]byte(imagesJSON), &images)
			if err != nil {
				log.Printf("Error unmarshaling images JSON for post %s: %v", postWithComment.Id, err)
				images = []model.PostImage{} // fallback to empty slice
			}
		}
		postWithComment.Images = images

		// Handle latest comment if it exists
		if latestCommentID.Valid {
			latestComment := &model.Comment{
				Id:        latestCommentID.String,
				UserId:    latestCommentUserID.String,
				PostId:    latestCommentPostID.String,
				Content:   latestCommentContent.String,
				CreatedAt: latestCommentCreatedAt.String,
				UpdatedAt: latestCommentUpdatedAt.String,
			}

			// Handle nullable parent_id
			if latestCommentParentID.Valid {
				latestComment.ParentId = &latestCommentParentID.String
			}

			postWithComment.LatestComment = latestComment
		}

		postsWithComments = append(postsWithComments, postWithComment)
	}

	return postsWithComments, nil
}

// GetAllPostsByUserIdWithComments returns all posts by a specific user with their latest comment and total comment count
func (repo *Repository) GetAllPostsByUserIdWithComments(targetUserId string, limit, offset int, currentUserId string) ([]model.PostWithComment, error) {
	if targetUserId == "" {
		return nil, db.ErrUserIDMissing
	}
	if limit <= 0 {
		return nil, db.ErrInvalidLimit
	}
	if offset < 0 {
		return nil, db.ErrInvalidOffset
	}

	var postsWithComments []model.PostWithComment
	query := `
		SELECT 
			p.id, p.user_id, p.created_at, p.updated_at, p.content, 
			COALESCE(p.tags, '') as tags, COALESCE(p.like_count, 0) as like_count,
			COALESCE(
				json_agg(
					json_build_object('id', pi.id, 'post_id', pi.post_id, 'image_url', pi.image_url)
				) FILTER (WHERE pi.id IS NOT NULL), 
				'[]'
			) as images,
			-- Latest comment subquery
			lc.id as latest_comment_id,
			lc.userid as latest_comment_user_id,
			lc.postid as latest_comment_post_id,
			lc.parentid as latest_comment_parent_id,
			lc.content as latest_comment_content,
			lc.createdat as latest_comment_created_at,
			lc.updatedat as latest_comment_updated_at,
			-- Total comment count
			COALESCE(cc.total_comments, 0) as total_comments,
			-- Check if current user liked this post
			CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as user_liked
		FROM "Post" p
		LEFT JOIN "PostImages" pi ON p.id = pi.post_id
		LEFT JOIN LATERAL (
			SELECT id, userid, postid, parentid, content, createdat, updatedat
			FROM "Comment" c
			WHERE c.postid = p.id AND c.parentid IS NULL
			ORDER BY c.createdat DESC
			LIMIT 1
		) lc ON true
		LEFT JOIN (
			SELECT postid, COUNT(*) as total_comments
			FROM "Comment"
			GROUP BY postid
		) cc ON cc.postid = p.id
		LEFT JOIN "post_likes" pl ON p.id = pl.post_id AND pl.user_id = $4
		WHERE p.user_id = $1
		GROUP BY p.id, p.user_id, p.created_at, p.updated_at, p.content, p.tags, p.like_count,
				 lc.id, lc.userid, lc.postid, lc.parentid, lc.content, lc.createdat, lc.updatedat,
				 cc.total_comments, pl.user_id
		ORDER BY p.created_at DESC 
		LIMIT $2 OFFSET $3`

	rows, err := repo.DB.Query(query, targetUserId, limit, offset, currentUserId)
	if err != nil {
		log.Printf("Critical error getting posts by user ID %s with comments: %v", targetUserId, err)
		return nil, db.NewDatabaseError("select", "Post", err)
	}
	defer rows.Close()

	for rows.Next() {
		var postWithComment model.PostWithComment
		var imagesJSON string
		var latestCommentID, latestCommentUserID, latestCommentPostID sql.NullString
		var latestCommentParentID sql.NullString
		var latestCommentContent, latestCommentCreatedAt, latestCommentUpdatedAt sql.NullString

		err := rows.Scan(
			&postWithComment.Id, &postWithComment.UserId, &postWithComment.CreatedAt, &postWithComment.UpdatedAt,
			&postWithComment.Content, &postWithComment.Tags, &postWithComment.LikeCount, &imagesJSON,
			&latestCommentID, &latestCommentUserID, &latestCommentPostID, &latestCommentParentID,
			&latestCommentContent, &latestCommentCreatedAt, &latestCommentUpdatedAt,
			&postWithComment.TotalComments, &postWithComment.UserLiked)
		if err != nil {
			log.Printf("Critical error scanning post with comment data: %v", err)
			continue
		}

		// Parse images JSON
		var images []model.PostImage
		if imagesJSON != "[]" && imagesJSON != "" {
			err = json.Unmarshal([]byte(imagesJSON), &images)
			if err != nil {
				log.Printf("Error unmarshaling images JSON for post %s: %v", postWithComment.Id, err)
				images = []model.PostImage{} // fallback to empty slice
			}
		}
		postWithComment.Images = images

		// Handle latest comment if it exists
		if latestCommentID.Valid {
			latestComment := &model.Comment{
				Id:        latestCommentID.String,
				UserId:    latestCommentUserID.String,
				PostId:    latestCommentPostID.String,
				Content:   latestCommentContent.String,
				CreatedAt: latestCommentCreatedAt.String,
				UpdatedAt: latestCommentUpdatedAt.String,
			}

			// Handle nullable parent_id
			if latestCommentParentID.Valid {
				latestComment.ParentId = &latestCommentParentID.String
			}

			postWithComment.LatestComment = latestComment
		}

		postsWithComments = append(postsWithComments, postWithComment)
	}

	return postsWithComments, nil
}

// Helper function to convert comma-separated string to slice
func StringToTags(tagString string) []string {
	if tagString == "" {
		return []string{}
	}
	return strings.Split(tagString, ",")
}

// Helper function to convert slice to comma-separated string
func TagsToString(tags []string) string {
	return strings.Join(tags, ",")
}
