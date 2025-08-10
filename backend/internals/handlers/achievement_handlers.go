package handlers

import (
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
	"sportsin_backend/internals/services"
)

type CreateAchievementRequest struct {
	Date            string      `json:"date" binding:"required"`
	SportId         string      `json:"sport_id" binding:"required"`
	TournamentTitle string      `json:"tournament_title" binding:"required"`
	Description     string      `json:"description"`
	Level           model.Level `json:"level" binding:"required"`
	Stats           any         `json:"stats"`
}

type UpdateAchievementRequest struct {
	Date            string      `json:"date"`
	SportId         string      `json:"sport_id"`
	TournamentTitle string      `json:"tournament_title"`
	Description     string      `json:"description"`
	Level           model.Level `json:"level"`
	Stats           any         `json:"stats"`
}

type AchievementResponse struct {
	ID              string      `json:"id"`
	UserId          string      `json:"user_id"`
	Date            string      `json:"date"`
	SportId         string      `json:"sport_id"`
	TournamentTitle string      `json:"tournament_title"`
	Description     string      `json:"description"`
	Level           model.Level `json:"level"`
	Stats           any         `json:"stats"`
	CertificateUrl  *string     `json:"certificate_url,omitempty"`
}

type CertificateUploadResponse struct {
	CertificateURL string `json:"certificate_url"`
	Message        string `json:"message"`
}

// CreateAchievement godoc
// @Summary Create a new achievement
// @Description Create a new achievement for the authenticated user
// @Tags achievements
// @Accept json
// @Produce json
// @Param achievement body CreateAchievementRequest true "Achievement data"
// @Success 201 {object} AchievementResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements [post]
// @Security BearerAuth
func CreateAchievement(cfg *config.Config, repo *repositories.Repository) gin.HandlerFunc {
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

		var req CreateAchievementRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Invalid request body: " + err.Error(),
			})
			return
		}

		// Validate date format
		if _, err := time.Parse("2006-01-02", req.Date); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Invalid date format. Use YYYY-MM-DD",
			})
			return
		}

		// Create achievement model
		achievement := &model.Achievement{
			UserId:      userIDStr,
			Date:        req.Date,
			SportId:     req.SportId,
			Tournament:  req.TournamentTitle,
			Description: req.Description,
			Level:       req.Level,
			Stats:       req.Stats,
		}

		// Save to database
		if err := repo.CreateAchievement(userIDStr, achievement); err != nil {
			log.Printf("Error creating achievement: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to create achievement",
			})
			return
		}

		response := AchievementResponse{
			ID:              achievement.Id,
			UserId:          achievement.UserId,
			Date:            achievement.Date,
			SportId:         achievement.SportId,
			TournamentTitle: achievement.Tournament,
			Description:     achievement.Description,
			Level:           achievement.Level,
			Stats:           achievement.Stats,
			CertificateUrl:  achievement.CertificateUrl,
		}

		c.JSON(http.StatusCreated, response)
	}
}

// GetUserAchievements godoc
// @Summary Get user achievements
// @Description Get all achievements for the authenticated user
// @Tags achievements
// @Produce json
// @Success 200 {array} AchievementResponse
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements [get]
// @Security BearerAuth
func GetUserAchievements(cfg *config.Config, repo *repositories.Repository) gin.HandlerFunc {
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

		achievements, err := repo.GetAchievementsByUserId(userIDStr)
		if err != nil {
			log.Printf("Error fetching achievements: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to fetch achievements",
			})
			return
		}

		var response []AchievementResponse
		for _, achievement := range achievements {
			response = append(response, AchievementResponse{
				ID:              achievement.Id,
				UserId:          achievement.UserId,
				Date:            achievement.Date,
				SportId:         achievement.SportId,
				TournamentTitle: achievement.Tournament,
				Description:     achievement.Description,
				Level:           achievement.Level,
				Stats:           achievement.Stats,
				CertificateUrl:  achievement.CertificateUrl,
			})
		}

		c.JSON(http.StatusOK, response)
	}
}

// GetAchievementByID godoc
// @Summary Get achievement by ID
// @Description Get a specific achievement by its ID
// @Tags achievements
// @Produce json
// @Param id path string true "Achievement ID"
// @Success 200 {object} AchievementResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements/{id} [get]
// @Security BearerAuth
func GetAchievementByID(cfg *config.Config, repo *repositories.Repository) gin.HandlerFunc {
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

		achievementID := c.Param("id")
		if achievementID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Achievement ID is required",
			})
			return
		}

		achievement, err := repo.GetAchievementById(achievementID)
		if err != nil {
			log.Printf("Error fetching achievement: %v", err)
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "Achievement not found",
			})
			return
		}

		// Check if the achievement belongs to the authenticated user
		if achievement.UserId != userIDStr {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "You can only access your own achievements",
			})
			return
		}

		response := AchievementResponse{
			ID:              achievement.Id,
			UserId:          achievement.UserId,
			Date:            achievement.Date,
			SportId:         achievement.SportId,
			TournamentTitle: achievement.Tournament,
			Description:     achievement.Description,
			Level:           achievement.Level,
			Stats:           achievement.Stats,
			CertificateUrl:  achievement.CertificateUrl,
		}

		c.JSON(http.StatusOK, response)
	}
}

// UpdateAchievement godoc
// @Summary Update achievement
// @Description Update an existing achievement
// @Tags achievements
// @Accept json
// @Produce json
// @Param id path string true "Achievement ID"
// @Param achievement body UpdateAchievementRequest true "Updated achievement data"
// @Success 200 {object} AchievementResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements/{id} [put]
// @Security BearerAuth
func UpdateAchievement(cfg *config.Config, repo *repositories.Repository) gin.HandlerFunc {
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

		achievementID := c.Param("id")
		if achievementID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Achievement ID is required",
			})
			return
		}

		var req UpdateAchievementRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Invalid request body: " + err.Error(),
			})
			return
		}

		// Get existing achievement
		existingAchievement, err := repo.GetAchievementById(achievementID)
		if err != nil {
			log.Printf("Error fetching achievement: %v", err)
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "Achievement not found",
			})
			return
		}

		// Check if the achievement belongs to the authenticated user
		if existingAchievement.UserId != userIDStr {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "You can only update your own achievements",
			})
			return
		}

		// Update only provided fields
		if req.Date != "" {
			if _, err := time.Parse("2006-01-02", req.Date); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":   "Bad Request",
					"message": "Invalid date format. Use YYYY-MM-DD",
				})
				return
			}
			existingAchievement.Date = req.Date
		}
		if req.SportId != "" {
			existingAchievement.SportId = req.SportId
		}
		if req.TournamentTitle != "" {
			existingAchievement.Tournament = req.TournamentTitle
		}
		if req.Description != "" {
			existingAchievement.Description = req.Description
		}
		if req.Level != "" {
			existingAchievement.Level = req.Level
		}
		if req.Stats != nil {
			existingAchievement.Stats = req.Stats
		}

		// Update in database
		if err := repo.UpdateAchievement(existingAchievement); err != nil {
			log.Printf("Error updating achievement: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to update achievement",
			})
			return
		}

		response := AchievementResponse{
			ID:              existingAchievement.Id,
			UserId:          existingAchievement.UserId,
			Date:            existingAchievement.Date,
			SportId:         existingAchievement.SportId,
			TournamentTitle: existingAchievement.Tournament,
			Description:     existingAchievement.Description,
			Level:           existingAchievement.Level,
			Stats:           existingAchievement.Stats,
			CertificateUrl:  existingAchievement.CertificateUrl,
		}

		c.JSON(http.StatusOK, response)
	}
}

// DeleteAchievement godoc
// @Summary Delete achievement
// @Description Delete an existing achievement and its certificate
// @Tags achievements
// @Produce json
// @Param id path string true "Achievement ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements/{id} [delete]
// @Security BearerAuth
func DeleteAchievement(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
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

		achievementID := c.Param("id")
		if achievementID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Achievement ID is required",
			})
			return
		}

		// Get existing achievement
		existingAchievement, err := repo.GetAchievementById(achievementID)
		if err != nil {
			log.Printf("Error fetching achievement: %v", err)
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "Achievement not found",
			})
			return
		}

		// Check if the achievement belongs to the authenticated user
		if existingAchievement.UserId != userIDStr {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "You can only delete your own achievements",
			})
			return
		}

		// Delete certificate from S3 if it exists
		if existingAchievement.CertificateUrl != nil && *existingAchievement.CertificateUrl != "" {
			if err := s3Service.DeleteCertificate(c.Request.Context(), *existingAchievement.CertificateUrl); err != nil {
				log.Printf("Warning: Failed to delete certificate from S3: %v", err)
				// Continue with database deletion even if S3 deletion fails
			}
		}

		// Delete from database
		if err := repo.DeleteAchievementById(achievementID); err != nil {
			log.Printf("Error deleting achievement: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to delete achievement",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Achievement deleted successfully",
		})
	}
}

// UploadCertificate godoc
// @Summary Upload achievement certificate
// @Description Upload a certificate image/PDF for an achievement
// @Tags achievements
// @Accept multipart/form-data
// @Produce json
// @Param id path string true "Achievement ID"
// @Param file formData file true "Certificate file (PDF, JPG, PNG, GIF)"
// @Success 200 {object} CertificateUploadResponse
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements/{id}/certificate [post]
// @Security BearerAuth
func UploadCertificate(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
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

		achievementID := c.Param("id")
		if achievementID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Achievement ID is required",
			})
			return
		}

		// Get existing achievement
		existingAchievement, err := repo.GetAchievementById(achievementID)
		if err != nil {
			log.Printf("Error fetching achievement: %v", err)
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "Achievement not found",
			})
			return
		}

		// Check if the achievement belongs to the authenticated user
		if existingAchievement.UserId != userIDStr {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "You can only upload certificates for your own achievements",
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

		// Validate file size (10MB limit for certificates)
		if header.Size > 10*1024*1024 {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "File size must be less than 10MB",
			})
			return
		}

		// Delete old certificate if it exists
		if existingAchievement.CertificateUrl != nil && *existingAchievement.CertificateUrl != "" {
			if err := s3Service.DeleteCertificate(c.Request.Context(), *existingAchievement.CertificateUrl); err != nil {
				log.Printf("Warning: Failed to delete old certificate from S3: %v", err)
			}
		}

		// Upload new certificate to S3
		certificateURL, err := s3Service.UploadCertificate(c.Request.Context(), userIDStr, achievementID, file, header)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to upload certificate: " + err.Error(),
			})
			return
		}

		// Update achievement with certificate URL
		existingAchievement.CertificateUrl = &certificateURL
		if err := repo.UpdateAchievement(existingAchievement); err != nil {
			log.Printf("Error updating achievement with certificate URL: %v", err)
			// Try to delete the uploaded file from S3 since database update failed
			s3Service.DeleteCertificate(c.Request.Context(), certificateURL)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to update achievement with certificate URL",
			})
			return
		}

		c.JSON(http.StatusOK, CertificateUploadResponse{
			CertificateURL: certificateURL,
			Message:        "Certificate uploaded successfully",
		})
	}
}

// DeleteCertificate godoc
// @Summary Delete achievement certificate
// @Description Delete the certificate for an achievement
// @Tags achievements
// @Produce json
// @Param id path string true "Achievement ID"
// @Success 200 {object} map[string]string
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 403 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /achievements/{id}/certificate [delete]
// @Security BearerAuth
func DeleteCertificate(cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
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

		achievementID := c.Param("id")
		if achievementID == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":   "Bad Request",
				"message": "Achievement ID is required",
			})
			return
		}

		// Get existing achievement
		existingAchievement, err := repo.GetAchievementById(achievementID)
		if err != nil {
			log.Printf("Error fetching achievement: %v", err)
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "Achievement not found",
			})
			return
		}

		// Check if the achievement belongs to the authenticated user
		if existingAchievement.UserId != userIDStr {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Forbidden",
				"message": "You can only delete certificates for your own achievements",
			})
			return
		}

		// Check if certificate exists
		if existingAchievement.CertificateUrl == nil || *existingAchievement.CertificateUrl == "" {
			c.JSON(http.StatusNotFound, gin.H{
				"error":   "Not Found",
				"message": "No certificate found for this achievement",
			})
			return
		}

		// Delete certificate from S3
		if err := s3Service.DeleteCertificate(c.Request.Context(), *existingAchievement.CertificateUrl); err != nil {
			log.Printf("Error deleting certificate from S3: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to delete certificate from storage",
			})
			return
		}

		// Update achievement to remove certificate URL
		existingAchievement.CertificateUrl = nil
		if err := repo.UpdateAchievement(existingAchievement); err != nil {
			log.Printf("Error updating achievement after certificate deletion: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Internal Server Error",
				"message": "Failed to update achievement record",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Certificate deleted successfully",
		})
	}
}

// RegisterAchievementRoutes registers all achievement-related routes
func RegisterAchievementRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) {
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)
	r := rg.Group("/achievements")
	r.Use(jwtMiddleware.AuthMiddleware())

	r.POST("", CreateAchievement(cfg, repo))
	r.GET("", GetUserAchievements(cfg, repo))
	r.GET("/:id", GetAchievementByID(cfg, repo))
	r.PUT("/:id", UpdateAchievement(cfg, repo))
	r.DELETE("/:id", DeleteAchievement(cfg, repo, s3Service))
	r.POST("/:id/certificate", UploadCertificate(cfg, repo, s3Service))
	r.DELETE("/:id/certificate", DeleteCertificate(cfg, repo, s3Service))
}
