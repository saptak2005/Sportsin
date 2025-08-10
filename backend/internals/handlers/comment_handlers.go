package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
)

// CreateComment godoc
// @Summary      Create a new comment
// @Description  Creates a new comment on a post, or a reply to an existing comment
// @Tags         comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        createCommentInput  body     model.CreateCommentRequest  true  "Comment data"
// @Success      201  {object}  model.Comment
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /comments [post]
func CreateCommentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		var req model.CreateCommentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		// Create comment
		comment, err := repo.CreateComment(userID, req.PostId, req.Content, req.ParentId)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusCreated, comment)
	}
}

// GetCommentsByPostId godoc
// @Summary      Get comments for a post
// @Description  Retrieves all top-level comments for a post with their latest replies
// @Tags         comments
// @Accept       json
// @Produce      json
// @Param        id  path   string  true   "Post ID"
// @Param        limit    query  int     false  "Number of comments to return (default: 10, max: 50)"
// @Param        offset   query  int     false  "Number of comments to skip (default: 0)"
// @Success      200  {array}   model.CommentResponse
// @Failure      400  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /posts/{id}/comments [get]
func GetCommentsByPostIdHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		postID := c.Param("id")
		if postID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("post_id", "post ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Parse pagination parameters
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 50 {
			limit = 10
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			offset = 0
		}

		// Get comments
		comments, err := repo.GetCommentsByPostId(postID, limit, offset)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, comments)
	}
}

// GetCommentById godoc
// @Summary      Get a specific comment with its replies
// @Description  Retrieves a comment by ID with paginated replies
// @Tags         comments
// @Accept       json
// @Produce      json
// @Param        id           path   string  true   "Comment ID"
// @Param        reply_limit  query  int     false  "Number of replies to return (default: 10, max: 50)"
// @Param        reply_offset query  int     false  "Number of replies to skip (default: 0)"
// @Success      200  {object}  model.CommentResponse
// @Failure      400  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /comments/{id} [get]
func GetCommentByIdHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		commentID := c.Param("id")
		if commentID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("comment_id", "comment ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Parse pagination parameters for replies
		replyLimitStr := c.DefaultQuery("reply_limit", "10")
		replyOffsetStr := c.DefaultQuery("reply_offset", "0")

		replyLimit, err := strconv.Atoi(replyLimitStr)
		if err != nil || replyLimit < 0 || replyLimit > 50 {
			replyLimit = 10
		}

		replyOffset, err := strconv.Atoi(replyOffsetStr)
		if err != nil || replyOffset < 0 {
			replyOffset = 0
		}

		// Get comment with replies
		commentResponse, err := repo.GetCommentById(commentID, replyLimit, replyOffset)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, commentResponse)
	}
}

// UpdateComment godoc
// @Summary      Update a comment
// @Description  Updates the content of a comment (only by the comment author)
// @Tags         comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id                  path  string                        true  "Comment ID"
// @Param        updateCommentInput  body  model.UpdateCommentRequest    true  "Updated comment data"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /comments/{id} [put]
func UpdateCommentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		commentID := c.Param("id")
		if commentID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("comment_id", "comment ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		var req model.UpdateCommentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		// First, get the comment to check ownership
		commentResponse, err := repo.GetCommentById(commentID, 0, 0)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user owns the comment
		if commentResponse.Comment.UserId != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own comments"})
			return
		}

		// Update comment
		err = repo.UpdateComment(commentID, req.Content)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Comment updated successfully"})
	}
}

// DeleteComment godoc
// @Summary      Delete a comment
// @Description  Deletes a comment (only by the comment author)
// @Tags         comments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "Comment ID"
// @Success      200  {object}  map[string]string
// @Failure      400  {object}  map[string]string
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      404  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /comments/{id} [delete]
func DeleteCommentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		commentID := c.Param("id")
		if commentID == "" {
			httpErr := db.ToHTTPError(db.NewValidationError("comment_id", "comment ID is required"))
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// First, get the comment to check ownership
		commentResponse, err := repo.GetCommentById(commentID, 0, 0)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user owns the comment
		if commentResponse.Comment.UserId != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own comments"})
			return
		}

		// Delete comment
		err = repo.DeleteComment(commentID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Comment deleted successfully"})
	}
}

// RegisterCommentRoutes registers all comment-related routes
func RegisterCommentRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository) {
	// Initialize JWT middleware
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)

	// Public routes (no authentication required)
	rg.GET("/posts/:id/comments", GetCommentsByPostIdHandler(repo))
	rg.GET("/comments/:id", GetCommentByIdHandler(repo))

	// Protected routes (authentication required)
	protected := rg.Group("/")
	protected.Use(jwtMiddleware.AuthMiddleware())
	{
		protected.POST("/comments", CreateCommentHandler(repo))
		protected.PUT("/comments/:id", UpdateCommentHandler(repo))
		protected.DELETE("/comments/:id", DeleteCommentHandler(repo))
	}
}
