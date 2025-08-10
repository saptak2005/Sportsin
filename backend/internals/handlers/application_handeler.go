package handlers

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
)

type UpdateApplicationStatusRequest struct {
	Status model.ApplicationStatus `json:"status" binding:"required"`
}

type ApplicationResponse struct {
	ID        string                  `json:"id"`
	PlayerID  string                  `json:"player_id"`
	OpeningID string                  `json:"opening_id"`
	Status    model.ApplicationStatus `json:"status"`
	CreatedAt string                  `json:"created_at"`
	UpdatedAt string                  `json:"updated_at"`
}

type ApplicantResponse struct {
	ID              string                  `json:"id"`
	Status          model.ApplicationStatus `json:"status"`
	OpeningID       string                  `json:"opening_id"`
	Username        string                  `json:"username"`
	Email           string                  `json:"email"`
	Role            string                  `json:"role"`
	UserName        string                  `json:"user_name"`
	ProfilePicture  *string                 `json:"profile_picture,omitempty"`
	Name            string                  `json:"name"`
	MiddleName      *string                 `json:"middle_name,omitempty"`
	Surname         string                  `json:"surname"`
	DOB             string                  `json:"dob"`
	Gender          string                  `json:"gender"`
	About           *string                 `json:"about,omitempty"`
	Level           string                  `json:"level"`
	InterestLevel   string                  `json:"interest_level"`
	InterestCountry *string                 `json:"interest_country,omitempty"`
	CreatedAt       string                  `json:"created_at"`
	UpdatedAt       string                  `json:"updated_at"`
}

// Helper function to convert Application to ApplicationResponse
func toApplicationResponse(application *model.Application) *ApplicationResponse {
	return &ApplicationResponse{
		ID:        application.Id,
		PlayerID:  application.PlayerID,
		OpeningID: application.OpeningID,
		Status:    model.ApplicationStatus(application.Status),
		CreatedAt: application.CreatedAt,
		UpdatedAt: application.UpdatedAt,
	}
}

// Helper function to convert Player to PlayerResponse
func toPlayerResponse(applicant *model.Applicant) *ApplicantResponse {
	return &ApplicantResponse{
		ID:              applicant.Id,
		Status:          applicant.Status,
		OpeningID:       applicant.OpeningID,
		Username:        applicant.Username,
		Email:           applicant.Email,
		Role:            string(applicant.Role),
		UserName:        applicant.UserName,
		ProfilePicture:  applicant.ProfilePicture,
		Name:            applicant.Name,
		MiddleName:      applicant.MiddleName,
		Surname:         applicant.Surname,
		DOB:             applicant.DOB,
		Gender:          string(applicant.Gender),
		About:           applicant.About,
		Level:           string(applicant.Level),
		InterestLevel:   string(applicant.InterestLevel),
		InterestCountry: applicant.InterestCountry,
		CreatedAt:       applicant.CreatedAt,
		UpdatedAt:       applicant.UpdatedAt,
	}
}

// CreateApplication godoc
// @Summary      Apply to a job opening
// @Description  Creates a new job application for the authenticated player to a specific opening
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id           path      string                   true  "Opening ID"
// @Param        application  body      CreateApplicationRequest  true  "Application details"
// @Success      201          {object}  ApplicationResponse
// @Failure      400          {object}  map[string]string
// @Failure      401          {object}  map[string]string
// @Failure      403          {object}  map[string]string
// @Failure      409          {object}  map[string]string
// @Failure      500          {object}  map[string]string
// @Router       /openings/{id}/apply [post]
func CreateApplicationHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID and role from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		role, roleExists := middleware.GetRoleFromContext(c)
		if !roleExists || role != "player" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Only players can create applications"})
			return
		}

		// Get opening ID from URL path
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Create application model
		application := &model.Application{
			PlayerID:  userID,
			OpeningID: openingID,
			Status:    model.ApplicationStatusPending,
		}

		// Create application in database
		applicationID, err := repo.CreateApplication(application)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get the created application
		createdApplication, err := repo.GetApplicationByID(applicationID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusCreated, gin.H{"application": toApplicationResponse(createdApplication)})
	}
}

// GetApplicantsByOpeningID godoc
// @Summary      Get applicants for a specific opening
// @Description  Retrieves all players who have applied to a specific opening. Only the recruiter who owns the opening can access this.
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path      string  true  "Opening ID"
// @Success      200         {object}  object{applicants=[]PlayerResponse}
// @Failure      400         {object}  map[string]string
// @Failure      401         {object}  map[string]string
// @Failure      403         {object}  map[string]string
// @Failure      404         {object}  map[string]string
// @Failure      500         {object}  map[string]string
// @Router       /openings/{id}/applicants [get]
func GetApplicantsByOpeningIDHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID and role from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		role, roleExists := middleware.GetRoleFromContext(c)
		if !roleExists || role != "recruiter" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Only recruiters can view applicants"})
			return
		}

		// Get opening ID from URL
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Check if the opening exists and if the recruiter owns it
		opening, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			log.Println(err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Verify ownership
		if opening.Opening.RecruiterID != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only view applicants for your own openings"})
			return
		}

		// Get applicants for the opening
		applicants, err := repo.GetApplicantsByOpeningID(openingID)
		if err != nil {
			log.Println(err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Convert to response format
		responses := make([]ApplicantResponse, 0)
		for _, applicant := range applicants {
			responses = append(responses, *toPlayerResponse(applicant))
		}

		c.JSON(http.StatusOK, gin.H{"applicants": responses})
	}
}

// GetApplicationsByPlayer godoc
// @Summary      Get applications by player
// @Description  Retrieves all applications made by the authenticated player
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  object{applications=[]ApplicationResponse}
// @Failure      401  {object}  map[string]string
// @Failure      403  {object}  map[string]string
// @Failure      500  {object}  map[string]string
// @Router       /applications/my [get]
func GetApplicationsByPlayerHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID and role from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		role, roleExists := middleware.GetRoleFromContext(c)
		if !roleExists || role != "player" {
			c.JSON(http.StatusForbidden, gin.H{"error": "Only players can view their applications"})
			return
		}

		// Get applications from database
		applications, err := repo.GetApplicationsByPlayerID(userID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Convert to response format
		responses := make([]ApplicationResponse, 0)
		for _, application := range applications {
			responses = append(responses, *toApplicationResponse(application))
		}

		c.JSON(http.StatusOK, gin.H{"applications": responses})
	}
}

// AcceptApplication godoc
// @Summary      Accept an application
// @Description  Accepts an application for a specific opening. Only the recruiter who owns the opening can accept applications.
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id             path  string  true  "Opening ID"
// @Param        application_id path  string  true  "Application ID"
// @Success      200            {object}  map[string]ApplicationResponse
// @Failure      400            {object}  map[string]string
// @Failure      401            {object}  map[string]string
// @Failure      403            {object}  map[string]string
// @Failure      404            {object}  map[string]string
// @Failure      500            {object}  map[string]string
// @Router       /openings/{id}/applications/{application_id}/accept [patch]
func AcceptApplicationHandler(repo *repositories.Repository) gin.HandlerFunc {
	return updateApplicationStatusHandler(repo, model.ApplicationStatusAccepted, "accept", "recruiter")
}

// RejectApplication godoc
// @Summary      Reject an application
// @Description  Rejects an application for a specific opening. Only the recruiter who owns the opening can reject applications.
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id             path  string  true  "Opening ID"
// @Param        application_id path  string  true  "Application ID"
// @Success      200            {object}  map[string]ApplicationResponse
// @Failure      400            {object}  map[string]string
// @Failure      401            {object}  map[string]string
// @Failure      403            {object}  map[string]string
// @Failure      404            {object}  map[string]string
// @Failure      500            {object}  map[string]string
// @Router       /openings/{id}/applications/{application_id}/reject [patch]
func RejectApplicationHandler(repo *repositories.Repository) gin.HandlerFunc {
	return updateApplicationStatusHandler(repo, model.ApplicationStatusRejected, "reject", "recruiter")
}

// WithdrawApplication godoc
// @Summary      Withdraw an application
// @Description  Withdraws an application for a specific opening. Only the player who created the application can withdraw it.
// @Tags         applications
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id             path  string  true  "Opening ID"
// @Param        application_id path  string  true  "Application ID"
// @Success      200            {object}  map[string]ApplicationResponse
// @Failure      400            {object}  map[string]string
// @Failure      401            {object}  map[string]string
// @Failure      403            {object}  map[string]string
// @Failure      404            {object}  map[string]string
// @Failure      500            {object}  map[string]string
// @Router       /openings/{id}/applications/{application_id}/withdraw [patch]
func WithdrawApplicationHandler(repo *repositories.Repository) gin.HandlerFunc {
	return updateApplicationStatusHandler(repo, model.ApplicationStatusWithdrawn, "withdraw", "player")
}

// Helper function for updating application status
func updateApplicationStatusHandler(repo *repositories.Repository, status model.ApplicationStatus, action string, requiredRole string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID and role from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		role, roleExists := middleware.GetRoleFromContext(c)
		if !roleExists || role != requiredRole {
			c.JSON(http.StatusForbidden, gin.H{"error": "Insufficient permissions to " + action + " application"})
			return
		}

		// Get opening ID and application ID from URL
		openingID := c.Param("id")
		playerID := c.Param("applicant_id")
		if openingID == "" || playerID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID and Application ID are required"})
			return
		}

		// Validate playerID as a UUID
		if _, err := uuid.Parse(playerID); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid applicant ID format"})
			return
		}

		// Get the application to verify it exists and belongs to the opening
		application, err := repo.GetApplicationByPlayerIDAndOpeningID(playerID, openingID)
		if err != nil {
			log.Println("Error getting application:", err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		if application.Status == model.ApplicationStatusWithdrawn {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Application has already been withdrawn"})
			return
		}

		switch requiredRole {
		case "recruiter":
			opening, err := repo.GetOpeningByID(openingID, nil)
			if err != nil {
				log.Println("Error getting opening:", err)
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
			if opening.Opening.RecruiterID != userID {
				c.JSON(http.StatusForbidden, gin.H{"error": "You can only " + action + " applications for your own openings"})
				return
			}
		case "player":
			if application.PlayerID != userID {
				c.JSON(http.StatusForbidden, gin.H{"error": "You can only " + action + " your own applications"})
				return
			}

			if action != "withdraw" {
				c.JSON(http.StatusForbidden, gin.H{"error": "You can only " + action + " your own applications"})
			}
		}

		if err := repo.UpdateApplicationStatus(application.Id, status); err != nil {
			log.Println("Error updating application status:", err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get the updated application
		updatedApplication, err := repo.GetApplicationByID(application.Id)
		if err != nil {
			log.Println("Error getting updated application:", err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"application": toApplicationResponse(updatedApplication)})
	}
}
