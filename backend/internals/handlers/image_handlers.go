package handlers

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/services"
)

type ImageUploadResponse struct {
	ImageURL string `json:"image_url"`
	Message  string `json:"message"`
}

type ImageURLResponse struct {
	ImageURL string `json:"image_url"`
	UserID   string `json:"user_id"`
}

// UploadProfilePicture godoc
// @Summary Upload profile picture
// @Description Upload a profile picture for the authenticated user
// @Tags profile
// @Accept multipart/form-data
// @Produce json
// @Param file formData file true "Profile picture file"
// @Success 200 {object} ImageUploadResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /image/upload [post]
// @Security BearerAuth
func UploadProfilePicture(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from JWT token
		userID, uexists := c.Get("userID")
		email, eexists := c.Get("email")
		if !uexists || !eexists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "User ID not found in token",
			})
			return
		}

		userIDStr, ok := userID.(string)
		emailStr, eok := email.(string)
		if !ok || !eok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid user ID format",
			})
			return
		}

		// Get file from form data
		file, header, err := c.Request.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "No file provided or invalid file",
			})
			return
		}
		defer file.Close()

		// Validate file size (5MB limit)
		if header.Size > 5*1024*1024 {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "File size must be less than 5MB",
			})
			return
		}

		// Upload to S3
		imageURL, err := s3Service.UploadProfilePicture(c.Request.Context(), userIDStr, file, header)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to upload image: " + err.Error(),
			})
			return
		}

		err = repo.UpdateProfilePicture(
			emailStr,
			imageURL,
		)

		if err != nil {
			log.Printf("ERROR: failed to update profile picture: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Internal Server Error",
			})
			return
		}

		c.JSON(http.StatusOK, ImageUploadResponse{
			ImageURL: imageURL,
			Message:  "Profile picture uploaded successfully",
		})
	}
}

// GetProfilePictureURL godoc
// @Summary Get profile picture URL
// @Description Get the S3 URL for a user's profile picture
// @Tags profile
// @Produce json
// @Param user_id query string false "User ID (defaults to authenticated user)"
// @Param extension query string false "File extension (defaults to .jpg)"
// @Success 200 {object} ImageURLResponse
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /image [get]
// @Security BearerAuth
func GetProfilePictureURL(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from JWT token
		userID, exists := c.Get("userID")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "User ID not found in token",
			})
			return
		}

		userIDStr, ok := userID.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid user ID format",
			})
			return
		}

		// Check if a specific user ID is requested (for viewing other users' profiles)
		queryUserID := c.Query("user_id")
		if queryUserID != "" {
			userIDStr = queryUserID
		}

		// Get file extension from query params or default to .jpg
		extension := c.DefaultQuery("extension", ".jpg")
		if !strings.HasPrefix(extension, ".") {
			extension = "." + extension
		}

		// Generate S3 URL
		imageURL := s3Service.GetProfilePictureURL(userIDStr, extension)

		c.JSON(http.StatusOK, ImageURLResponse{
			ImageURL: imageURL,
			UserID:   userIDStr,
		})
	}
}

// DeleteProfilePicture godoc
// @Summary Delete profile picture
// @Description Delete the authenticated user's profile picture from S3
// @Tags profile
// @Produce json
// @Param extension query string false "File extension (defaults to .jpg)"
// @Success 200 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /image [delete]
// @Security BearerAuth
func DeleteProfilePicture(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from JWT token
		userID, exists := c.Get("userID")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "User ID not found in token",
			})
			return
		}

		userIDStr, ok := userID.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid user ID format",
			})
			return
		}

		// Get file extension from query params or default to .jpg
		extension := c.DefaultQuery("extension", ".jpg")
		if !strings.HasPrefix(extension, ".") {
			extension = "." + extension
		}

		// Delete from S3
		err := s3Service.DeleteProfilePicture(c.Request.Context(), userIDStr, extension)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to delete image: " + err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Profile picture deleted successfully",
		})
	}
}

// RegisterImageRoutes registers all image-related routes
func RegisterImageRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) {
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)
	r := rg.Group("/image")
	r.Use(jwtMiddleware.AuthMiddleware())
	r.POST("/upload", UploadProfilePicture(cfg, repo, s3Service))
	r.GET("", GetProfilePictureURL(cfg, repo, s3Service))
	r.DELETE("", DeleteProfilePicture(cfg, repo, s3Service))
}
