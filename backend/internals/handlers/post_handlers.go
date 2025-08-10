package handlers

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
	"sportsin_backend/internals/services"
)

// CreatePost godoc
// @Summary      Create a new post
// @Description  Creates a new post for the authenticated user with optional images
// @Tags         posts
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        content     formData  string  true   "Post content"
// @Param        tags        formData  string  false  "Comma-separated tags"
// @Param        images      formData  file    false  "Post images (multiple allowed)"
// @Success      201  {object}  model.PostResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts [post]
func CreatePostHandler(repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Parse form data
		content := c.PostForm("content")
		if content == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("content", "content is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		tagsStr := c.PostForm("tags")

		// Create post object
		post := &model.Post{
			UserId:  userID,
			Content: content,
			Tags:    tagsStr,
		}

		// Create post in database
		if err := repo.CreatePost(post); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Handle image uploads if any
		var images []model.PostImage
		var imageErrors []string
		form, err := c.MultipartForm()
		if err != nil {
			fmt.Printf("DEBUG: Error getting multipart form: %v\n", err)
		} else if form.File["images"] == nil {
			fmt.Printf("DEBUG: No images field found in form\n")
		} else {
			fmt.Printf("DEBUG: Found %d images to process\n", len(form.File["images"]))
			ctx := context.Background()

			for i, fileHeader := range form.File["images"] {
				fmt.Printf("DEBUG: Processing image %d: %s\n", i, fileHeader.Filename)

				file, err := fileHeader.Open()
				if err != nil {
					errMsg := fmt.Sprintf("Failed to open image file %s: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					continue // Skip invalid files
				}
				defer file.Close()

				// Generate unique image ID
				imageID := fmt.Sprintf("img_%d_%d", i, time.Now().UnixNano())

				// Upload to S3
				imageURL, err := s3Service.UploadPostImage(ctx, post.Id, imageID, file, fileHeader)
				if err != nil {
					errMsg := fmt.Sprintf("Failed to upload image %s to S3: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					continue // Skip failed uploads
				}
				fmt.Printf("DEBUG: Successfully uploaded image to S3: %s\n", imageURL)

				// Create image record
				postImage := &model.PostImage{
					PostId:   post.Id,
					ImageUrl: imageURL,
				}

				if err := repo.CreatePostImage(postImage); err != nil {
					errMsg := fmt.Sprintf("Failed to save image %s to database: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					// Try to delete from S3 if database operation fails
					s3Service.DeletePostImage(ctx, imageURL)
					continue
				}
				fmt.Printf("DEBUG: Successfully created image record in DB with ID: %s\n", postImage.Id)

				images = append(images, *postImage)
			}
		}

		// Prepare response
		var tags []string
		if tagsStr != "" {
			tags = repositories.StringToTags(tagsStr)
		}

		createdAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.CreatedAt)
		updatedAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.UpdatedAt)

		// If at least one image was uploaded, return its URL as imageUrl (otherwise empty string)
		var imageUrl string
		if len(images) > 0 {
			imageUrl = images[0].ImageUrl
		}

		fmt.Printf("DEBUG: Final images array length: %d\n", len(images))
		if len(images) > 0 {
			fmt.Printf("DEBUG: First image URL: %s\n", imageUrl)
		}

		response := model.PostResponse{
			Id:        post.Id,
			Image_url: imageUrl,
			UserId:    post.UserId,
			Content:   post.Content,
			Tags:      tags,
			Images:    images,
			CreatedAt: createdAt,
			UpdatedAt: updatedAt,
		}

		// If there were image errors, include them in the response
		if len(imageErrors) > 0 {
			c.JSON(http.StatusCreated, gin.H{
				"post":         response,
				"image_errors": imageErrors,
				"message":      "Post created successfully, but some images failed to upload",
			})
		} else {
			c.JSON(http.StatusCreated, response)
		}
	}
}

// GetPost godoc
// @Summary      Get a post by ID
// @Description  Retrieves a specific post with its images
// @Tags         posts
// @Produce      json
// @Param        id   path      string  true  "Post ID"
// @Success      200  {object}  model.PostResponse
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id} [get]
func GetPostHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get post with images
		post, err := repo.GetPostById(postID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Prepare response
		var tags []string
		if post.Tags != "" {
			tags = repositories.StringToTags(post.Tags)
		}

		createdAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.CreatedAt)
		updatedAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.UpdatedAt)

		response := model.PostResponse{
			Id:        post.Id,
			UserId:    post.UserId,
			Content:   post.Content,
			Tags:      tags,
			Images:    post.Images,
			CreatedAt: createdAt,
			UpdatedAt: updatedAt,
			LikeCount: post.LikeCount,
		}

		c.JSON(http.StatusOK, response)
	}
}

// GetPosts godoc
// @Summary      Get posts
// @Description  Retrieves posts with pagination. If user_id is provided, gets posts for that user only.
// @Tags         posts
// @Produce      json
// @Param        user_id  query     string  false  "User ID to filter posts"
// @Param        limit    query     int     false  "Number of posts to return (default 10)"
// @Param        offset   query     int     false  "Number of posts to skip (default 0)"
// @Success      200  {array}   model.PostResponse
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts [get]
func GetPostsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.Query("user_id")

		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 100 {
			limit = 10
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			offset = 0
		}

		// Get posts with images
		var posts []model.Post
		if userID != "" {
			posts, err = repo.GetPostsByUserId(userID, limit, offset)
		} else {
			posts, err = repo.GetAllPosts(limit, offset)
		}
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Prepare response
		var responses []model.PostResponse
		for _, post := range posts {
			var tags []string
			if post.Tags != "" {
				tags = repositories.StringToTags(post.Tags)
			}

			createdAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.CreatedAt)
			updatedAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.UpdatedAt)

			response := model.PostResponse{
				Id:        post.Id,
				UserId:    post.UserId,
				Content:   post.Content,
				Tags:      tags,
				Images:    post.Images,
				CreatedAt: createdAt,
				UpdatedAt: updatedAt,
				LikeCount: post.LikeCount,
			}
			responses = append(responses, response)
		}

		c.JSON(http.StatusOK, responses)
	}
}

// GetPostsWithCommentsHandler godoc
// @Summary      Get all posts with comments
// @Description  Retrieves all posts with their latest comment and total comment count
// @Tags         posts
// @Accept       json
// @Produce      json
// @Param        limit    query  int     false  "Number of posts to return (default: 10, max: 100)"
// @Param        offset   query  int     false  "Number of posts to skip (default: 0)"
// @Success      200  {array}   model.PostWithComment
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/with-comments [get]
func GetPostsWithCommentsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		cUsrId, ok := middleware.GetUserIDFromContext(c)
		if !ok {
			c.JSON(http.StatusUnauthorized, "User not Authorized")
			return
		}
		fUsrId := c.Query("user_id")
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 100 {
			limit = 10
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			offset = 0
		}

		var postsWithComments []model.PostWithComment
		if fUsrId == "" {
			postsWithComments, err = repo.GetAllPostsWithComments(limit, offset, cUsrId)
		} else {
			postsWithComments, err = repo.GetAllPostsByUserIdWithComments(fUsrId, limit, offset, cUsrId)
		}
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, postsWithComments)
	}
}

// UpdatePost godoc
// @Summary      Update a post with images
// @Description  Updates a post owned by the authenticated user with optional new images
// @Tags         posts
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        id          path      string  true   "Post ID"
// @Param        content     formData  string  false  "Post content"
// @Param        tags        formData  string  false  "Comma-separated tags"
// @Param        images      formData  file    false  "Post images (multiple allowed)"
// @Param        replace_images formData string false "Set to 'true' to replace all existing images"
// @Success      200  {object}  model.PostResponse
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id} [put]
func UpdatePostHandler(repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user owns the post
		owns, err := repo.CheckPostOwnership(postID, userID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}
		if !owns {
			httpErr := db.ToHTTPError(db.NewAuthorizationError("update", "post", userID))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get existing post
		post, err := repo.GetPostById(postID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Parse form data
		content := c.PostForm("content")
		tagsStr := c.PostForm("tags")
		replaceImages := c.PostForm("replace_images") == "true"

		// Update fields if provided
		if content != "" {
			post.Content = content
		}
		if tagsStr != "" {
			post.Tags = tagsStr
		}

		// Update post in database
		if err := repo.UpdatePost(post); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Handle image uploads if any
		var imageErrors []string
		form, err := c.MultipartForm()
		if err != nil {
			fmt.Printf("DEBUG: Error getting multipart form: %v\n", err)
		} else if form.File["images"] != nil {
			fmt.Printf("DEBUG: Found %d new images to process\n", len(form.File["images"]))
			ctx := context.Background()

			// If replace_images is true, delete existing images first
			if replaceImages {
				fmt.Printf("DEBUG: Replacing existing images\n")
				imageUrls, err := repo.DeleteImagesByPostId(postID)
				if err != nil {
					httpErr := db.ToHTTPError(err)
					c.JSON(httpErr.StatusCode, httpErr)
					return
				}
				// Delete images from S3
				for _, imageUrl := range imageUrls {
					if err := s3Service.DeletePostImage(ctx, imageUrl); err != nil {
						fmt.Printf("ERROR: Failed to delete image from S3: %v\n", err)
					}
				}
			}

			// Upload new images
			for i, fileHeader := range form.File["images"] {
				fmt.Printf("DEBUG: Processing new image %d: %s\n", i, fileHeader.Filename)

				file, err := fileHeader.Open()
				if err != nil {
					errMsg := fmt.Sprintf("Failed to open image file %s: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					continue // Skip invalid files
				}
				defer file.Close()

				// Generate unique image ID
				imageID := fmt.Sprintf("img_%d_%d", i, time.Now().UnixNano())

				// Upload to S3
				imageURL, err := s3Service.UploadPostImage(ctx, post.Id, imageID, file, fileHeader)
				if err != nil {
					errMsg := fmt.Sprintf("Failed to upload image %s to S3: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					continue // Skip failed uploads
				}
				fmt.Printf("DEBUG: Successfully uploaded image to S3: %s\n", imageURL)

				// Create image record
				postImage := &model.PostImage{
					PostId:   post.Id,
					ImageUrl: imageURL,
				}

				if err := repo.CreatePostImage(postImage); err != nil {
					errMsg := fmt.Sprintf("Failed to save image %s to database: %v", fileHeader.Filename, err)
					fmt.Printf("ERROR: %s\n", errMsg)
					imageErrors = append(imageErrors, errMsg)
					// Try to delete from S3 if database operation fails
					s3Service.DeletePostImage(ctx, imageURL)
					continue
				}
				fmt.Printf("DEBUG: Successfully created image record in DB with ID: %s\n", postImage.Id)
			}
		}

		// Get updated post with all images
		post, err = repo.GetPostById(postID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Prepare response
		var tags []string
		if post.Tags != "" {
			tags = repositories.StringToTags(post.Tags)
		}

		createdAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.CreatedAt)
		updatedAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.UpdatedAt)

		// If at least one image exists, return its URL as imageUrl (otherwise empty string)
		var imageUrl string
		if len(post.Images) > 0 {
			imageUrl = post.Images[0].ImageUrl
		}

		response := model.PostResponse{
			Id:        post.Id,
			Image_url: imageUrl,
			UserId:    post.UserId,
			Content:   post.Content,
			Tags:      tags,
			Images:    post.Images,
			CreatedAt: createdAt,
			UpdatedAt: updatedAt,
			LikeCount: post.LikeCount,
		}

		// If there were image errors, include them in the response
		if len(imageErrors) > 0 {
			c.JSON(http.StatusOK, gin.H{
				"post":         response,
				"image_errors": imageErrors,
				"message":      "Post updated successfully, but some images failed to upload",
			})
		} else {
			c.JSON(http.StatusOK, response)
		}
	}
}

// DeletePost godoc
// @Summary      Delete a post
// @Description  Deletes a post owned by the authenticated user and all its images
// @Tags         posts
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "Post ID"
// @Success      200  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id} [delete]
func DeletePostHandler(repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user owns the post
		owns, err := repo.CheckPostOwnership(postID, userID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}
		if !owns {
			httpErr := db.ToHTTPError(db.NewAuthorizationError("delete", "post", userID))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Delete images from S3 and database
		ctx := context.Background()
		imageUrls, err := repo.DeleteImagesByPostId(postID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Delete images from S3
		for _, imageUrl := range imageUrls {
			if err := s3Service.DeletePostImage(ctx, imageUrl); err != nil {
				// Log error but continue with post deletion
				fmt.Printf("Failed to delete image from S3: %v\n", err)
			}
		}

		// Delete post from database
		if err := repo.DeletePost(postID, userID); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post deleted successfully"})
	}
}

// GetMyPosts godoc
// @Summary      Get current user's posts
// @Description  Retrieves posts created by the authenticated user
// @Tags         posts
// @Produce      json
// @Security     BearerAuth
// @Param        limit    query     int     false  "Number of posts to return (default 10)"
// @Param        offset   query     int     false  "Number of posts to skip (default 0)"
// @Success      200  {array}   model.PostResponse
// @Failure      401  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /my-posts [get]
func GetMyPostsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 100 {
			limit = 10
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			offset = 0
		}

		// Get user's posts with images
		posts, err := repo.GetPostsByUserId(userID, limit, offset)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Prepare response
		var responses []model.PostResponse
		for _, post := range posts {
			var tags []string
			if post.Tags != "" {
				tags = repositories.StringToTags(post.Tags)
			}

			createdAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.CreatedAt)
			updatedAt, _ := time.Parse("2006-01-02T15:04:05Z07:00", post.UpdatedAt)

			response := model.PostResponse{
				Id:        post.Id,
				UserId:    post.UserId,
				Content:   post.Content,
				Tags:      tags,
				Images:    post.Images,
				CreatedAt: createdAt,
				UpdatedAt: updatedAt,
				LikeCount: post.LikeCount,
			}
			responses = append(responses, response)
		}

		c.JSON(http.StatusOK, responses)
	}
}

// LikePost godoc
// @Summary      Like a post
// @Description  Adds a like to a specific post for the authenticated user
// @Tags         posts
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "Post ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id}/like [post]
func LikePostHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		if err := repo.LikePost(postID, userID); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post liked successfully"})
	}
}

// UnlikePost godoc
// @Summary      Unlike a post
// @Description  Removes a like from a specific post for the authenticated user
// @Tags         posts
// @Produce      json
// @Security     BearerAuth
// @Param        id   path      string  true  "Post ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id}/like [delete]
func UnlikePostHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		if err := repo.UnlikePost(postID, userID); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Post unliked successfully"})
	}
}

// RegisterPostRoutes registers all post-related routes
func RegisterPostRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) {
	// Initialize JWT middleware
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)

	// Public routes
	public := rg.Group("")
	{
		public.GET("/posts", GetPostsHandler(repo))
		public.GET("/posts/:id", GetPostHandler(repo))
	}

	// Protected routes (authentication required)
	protected := rg.Group("")
	protected.Use(jwtMiddleware.AuthMiddleware())
	{
		protected.GET("/posts/with-comments", GetPostsWithCommentsHandler(repo))
		protected.POST("/posts", CreatePostHandler(repo, s3Service))
		protected.PUT("/posts/:id", UpdatePostHandler(repo, s3Service))
		protected.DELETE("/posts/:id", DeletePostHandler(repo, s3Service))
		protected.GET("/my-posts", GetMyPostsHandler(repo))

		// Like and Unlike routes
		protected.POST("/posts/:id/like", LikePostHandler(repo))
		protected.DELETE("/posts/:id/like", UnlikePostHandler(repo))
	}
}
