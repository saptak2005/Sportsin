package repositories

import (
	"database/sql"
	"log"

	"sportsin_backend/internals/db"
	"sportsin_backend/internals/model"
)

// CreatePostImage creates a new post image record in the database
func (repo *Repository) CreatePostImage(postImage *model.PostImage) error {
	query := `INSERT INTO "PostImages" (id, post_id, image_url)
			  VALUES (gen_random_uuid(), $1, $2)
			  RETURNING id`

	err := repo.DB.QueryRow(query, postImage.PostId, postImage.ImageUrl).Scan(&postImage.Id)
	if err != nil {
		log.Printf("Error creating post image: %v", err)
		return db.NewDatabaseError("insert", "PostImages", err)
	}

	return nil
}

func (repo *Repository) GetImagesByPostId(postId string) ([]model.PostImage, error) {
	var images []model.PostImage
	query := `SELECT id, post_id, image_url FROM "PostImages" WHERE post_id = $1 ORDER BY id`

	rows, err := repo.DB.Query(query, postId)
	if err != nil {
		log.Printf("Error getting images by post ID: %v", err)
		return nil, db.NewDatabaseError("select", "PostImages", err)
	}
	defer rows.Close()

	for rows.Next() {
		var image model.PostImage
		err := rows.Scan(&image.Id, &image.PostId, &image.ImageUrl)
		if err != nil {
			log.Printf("Error scanning post image: %v", err)
			continue
		}
		images = append(images, image)
	}

	return images, nil
}

func (repo *Repository) DeleteImagesByPostId(postId string) ([]string, error) {
	var imageUrls []string
	selectQuery := `SELECT image_url FROM "PostImages" WHERE post_id = $1`

	rows, err := repo.DB.Query(selectQuery, postId)
	if err != nil {
		log.Printf("Error getting image URLs for deletion: %v", err)
		return nil, db.NewDatabaseError("select", "PostImages", err)
	}
	defer rows.Close()

	for rows.Next() {
		var imageUrl string
		err := rows.Scan(&imageUrl)
		if err != nil {
			log.Printf("Error scanning image URL: %v", err)
			continue
		}
		imageUrls = append(imageUrls, imageUrl)
	}

	deleteQuery := `DELETE FROM "PostImages" WHERE post_id = $1`
	_, err = repo.DB.Exec(deleteQuery, postId)
	if err != nil {
		log.Printf("Error deleting post images: %v", err)
		return imageUrls, db.NewDatabaseError("delete", "PostImages", err)
	}

	return imageUrls, nil
}

func (repo *Repository) DeletePostImage(imageId string) (string, error) {
	var imageUrl string
	query := `DELETE FROM "PostImages" WHERE id = $1 RETURNING image_url`

	err := repo.DB.QueryRow(query, imageId).Scan(&imageUrl)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", db.NewNotFoundError("post image", imageId)
		}
		log.Printf("Error deleting post image: %v", err)
		return "", db.NewDatabaseError("delete", "PostImages", err)
	}

	return imageUrl, nil
}
