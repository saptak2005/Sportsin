package repositories

import (
	"database/sql"
	"fmt"
	"log"

	"sportsin_backend/internals/db"
)

// LikePost adds a like to a post and increments the post's like_count.
// It performs these operations in a single database transaction.
func (repo *Repository) LikePost(postID, userID string) error {
	tx, err := repo.DB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	// Defer a rollback. If the transaction is committed, this is a no-op.
	defer func() {
		if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
			log.Printf("Failed to rollback transaction: %v", err)
		}
	}()

	// 1. Insert a record into the post_likes table.
	_, err = tx.Exec(`INSERT INTO "post_likes" (post_id, user_id) VALUES ($1, $2)`, postID, userID)
	if err != nil {
		log.Printf("Error creating post like: %v", err)
		return db.NewDatabaseError("insert", "post_likes", err)
	}

	// 2. Increment the like_count in the Post table.
	_, err = tx.Exec(`UPDATE "Post" SET like_count = like_count + 1 WHERE id = $1`, postID)
	if err != nil {
		log.Printf("Error incrementing post like count: %v", err)
		return fmt.Errorf("failed to increment post like count: %w", err)
	}

	// Commit the transaction.
	return tx.Commit()
}

// UnlikePost removes a like from a post and decrements the post's like_count.
// It performs these operations in a single database transaction.
func (repo *Repository) UnlikePost(postID, userID string) error {
	tx, err := repo.DB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	// Defer a rollback. If the transaction is committed, this is a no-op.
	defer func() {
		if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
			log.Printf("Failed to rollback transaction: %v", err)
		}
	}()

	// 1. Delete the record from the post_likes table.
	_, err = tx.Exec(`DELETE FROM "post_likes" WHERE post_id = $1 AND user_id = $2`, postID, userID)
	if err != nil {
		log.Printf("Error deleting post like: %v", err)
		return fmt.Errorf("failed to delete post like: %w", err)
	}

	// 2. Decrement the like_count in the Post table.
	_, err = tx.Exec(`UPDATE "Post" SET like_count = like_count - 1 WHERE id = $1`, postID)
	if err != nil {
		log.Printf("Error decrementing post like count: %v", err)
		return fmt.Errorf("failed to decrement post like count: %w", err)
	}

	// Commit the transaction.
	return tx.Commit()
}
