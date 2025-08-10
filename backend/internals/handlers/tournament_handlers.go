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

type CreateTournamentRequest struct {
	Title       string                  `json:"title" binding:"required"`
	Description *string                 `json:"description,omitempty"`
	Location    string                  `json:"location" binding:"required"`
	SportId     string                  `json:"sport_id" binding:"required"`
	MinAge      *int                    `json:"min_age,omitempty"`
	MaxAge      *int                    `json:"max_age,omitempty"`
	Level       *model.Level            `json:"level,omitempty" enums:"district,state,country,international,personal"`
	Gender      *model.Gender           `json:"gender,omitempty" enums:"male,female,other,rather_not_say"`
	Country     *string                 `json:"country,omitempty"`
	Status      *model.TournamentStatus `json:"status,omitempty" enums:"scheduled,started,ended,cancelled"`
	StartDate   string                  `json:"start_date" binding:"required"`
	EndDate     string                  `json:"end_date" binding:"required"`
	BannerUrl   *string                 `json:"banner_url,omitempty"`
}

type UpdateTournamentRequest struct {
	Title       string                  `json:"title,omitempty"`
	Description *string                 `json:"description,omitempty"`
	Location    string                  `json:"location,omitempty"`
	SportId     string                  `json:"sport_id,omitempty"`
	MinAge      *int                    `json:"min_age,omitempty"`
	MaxAge      *int                    `json:"max_age,omitempty"`
	Level       *model.Level            `json:"level,omitempty" enums:"district,state,country,international,personal"`
	Gender      *model.Gender           `json:"gender,omitempty" enums:"male,female,other,rather_not_say"`
	Country     *string                 `json:"country,omitempty"`
	Status      *model.TournamentStatus `json:"status,omitempty" enums:"scheduled,started,ended,cancelled"`
	StartDate   string                  `json:"start_date,omitempty"`
	EndDate     string                  `json:"end_date,omitempty"`
	BannerUrl   *string                 `json:"banner_url,omitempty"`
}

type JoinTournamentRequest struct {
	TournamentId string `json:"tournament_id" binding:"required"`
}

type UpdateParticipantStatusRequest struct {
	UserId string                    `json:"user_id" binding:"required"`
	Status model.ParticipationStatus `json:"status" binding:"required" enums:"pending,accepted,rejected"`
}

// CreateTournament godoc
// @Summary      Create a new tournament
// @Description  Creates a new tournament for the authenticated recruiter (host) with optional banner image
// @Tags         tournaments
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string  true   "Bearer JWT token"
// @Param        title         formData string  true   "Tournament title"
// @Param        description   formData string  false  "Tournament description"
// @Param        location      formData string  true   "Tournament location"
// @Param        sport_id      formData string  true   "Sport ID"
// @Param        min_age       formData int     false  "Minimum age"
// @Param        max_age       formData int     false  "Maximum age"
// @Param        level         formData string  false  "Tournament level"
// @Param        gender        formData string  false  "Gender restriction"
// @Param        country       formData string  false  "Country restriction"
// @Param        status        formData string  false  "Tournament status"
// @Param        start_date    formData string  true   "Start date (YYYY-MM-DD)"
// @Param        end_date      formData string  true   "End date (YYYY-MM-DD)"
// @Param        banner        formData file    false  "Tournament banner image"
// @Success      201           {object} model.Tournament          "Tournament created successfully"
// @Failure      400           {object} object{error=string}      "Invalid input data"
// @Failure      401           {object} object{error=string}      "Authentication required"
// @Failure      403           {object} object{error=string}      "Only recruiters can create tournaments"
// @Failure      500           {object} object{error=string}      "Internal server error"
// @Router       /tournaments [post]
func CreateTournamentHandler(repo *repositories.Repository, s3Service *services.S3Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Validate userID is not empty
		if userID == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid user ID",
			})
			return
		}

		// Debug: log the userID
		fmt.Printf("DEBUG: UserID from context: '%s'\n", userID)

		// Parse form data
		title := c.PostForm("title")
		if title == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Title is required",
			})
			return
		}

		location := c.PostForm("location")
		if location == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Location is required",
			})
			return
		}

		sportId := c.PostForm("sport_id")
		if sportId == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Sport ID is required",
			})
			return
		}

		startDate := c.PostForm("start_date")
		if startDate == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Start date is required",
			})
			return
		}

		endDate := c.PostForm("end_date")
		if endDate == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "End date is required",
			})
			return
		}

		// Optional fields
		description := c.PostForm("description")
		country := c.PostForm("country")
		levelStr := c.PostForm("level")
		genderStr := c.PostForm("gender")
		statusStr := c.PostForm("status")

		// Parse optional integer fields
		var minAge, maxAge *int
		if minAgeStr := c.PostForm("min_age"); minAgeStr != "" {
			if val, err := strconv.Atoi(minAgeStr); err == nil {
				minAge = &val
			}
		}
		if maxAgeStr := c.PostForm("max_age"); maxAgeStr != "" {
			if val, err := strconv.Atoi(maxAgeStr); err == nil {
				maxAge = &val
			}
		}

		// Parse enum fields
		var level *model.Level
		if levelStr != "" {
			l := model.Level(levelStr)
			level = &l
		}

		var gender *model.Gender
		if genderStr != "" {
			g := model.Gender(genderStr)
			gender = &g
		}

		var status *model.TournamentStatus
		if statusStr != "" {
			s := model.TournamentStatus(statusStr)
			status = &s
		} else {
			// Set default status
			defaultStatus := model.Scheduled
			status = &defaultStatus
		}

		// Create tournament model
		tournament := &model.Tournament{
			HostId:      userID,
			Title:       title,
			Description: &description,
			Location:    location,
			SportId:     sportId,
			MinAge:      minAge,
			MaxAge:      maxAge,
			Level:       level,
			Gender:      gender,
			Country:     &country,
			Status:      status,
			StartDate:   startDate,
			EndDate:     endDate,
		}

		// Handle banner image upload if provided
		if bannerFile, err := c.FormFile("banner"); err == nil {
			ctx := context.Background()

			// Open the file
			file, err := bannerFile.Open()
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Failed to open banner image",
				})
				return
			}
			defer file.Close()

			// Generate unique banner ID
			bannerID := fmt.Sprintf("banner_%d", time.Now().UnixNano())

			// Upload to S3 (we'll need to create this method)
			bannerURL, err := s3Service.UploadTournamentBanner(ctx, tournament.HostId, bannerID, file, bannerFile)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{
					"error": "Failed to upload banner image",
				})
				return
			}

			tournament.BannerUrl = &bannerURL
		}

		err := repo.CreateTournament(tournament)
		if err != nil {
			if tournament.BannerUrl != nil {
				ctx := context.Background()
				s3Service.DeleteTournamentBanner(ctx, *tournament.BannerUrl)
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to create tournament",
			})
			return
		}

		c.JSON(http.StatusCreated, tournament)
	}
}

// GetTournaments godoc
// @Summary      Get tournaments
// @Description  Retrieves tournaments with optional filtering by host, sport, or status
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization header  string  true   "Bearer JWT token"
// @Param        host_id   query  string  false  "Filter by host ID"
// @Param        sport_id  query  string  false  "Filter by sport ID"
// @Param        status    query  string  false  "Filter by status" Enums(scheduled,started,ended,cancelled)
// @Param        page      query  int     false  "Page number (default: 1)"
// @Param        limit     query  int     false  "Items per page (default: 10)"
// @Success      200       {array}  model.TournamentDetails "List of tournament details"
// @Failure      400       {object} object{error=string}     "Invalid query parameters"
// @Failure      401       {object} object{error=string}     "Authentication required"
// @Failure      500       {object} object{error=string}     "Internal server error"
// @Router       /tournaments [get]
func GetTournamentsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		hostID := c.Query("host_id")
		sportID := c.Query("sport_id")
		statusStr := c.Query("status")

		// Get user ID from authentication middleware (required now)
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		var tournamentDetails []*model.TournamentDetails
		var err error

		// Filter based on query parameters
		if hostID != "" {
			tournamentDetails, err = repo.GetTournamentDetailsByHostID(hostID, &userID)
		} else if sportID != "" {
			tournamentDetails, err = repo.GetTournamentDetailsBySportID(sportID, &userID)
		} else if statusStr != "" {
			status := model.TournamentStatus(statusStr)
			tournamentDetails, err = repo.GetTournamentDetailsByStatus(status, &userID)
		} else {
			tournamentDetails, err = repo.GetAllTournamentDetails(&userID)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournaments",
			})
			return
		}

		// Simple pagination
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))

		start := (page - 1) * limit
		end := start + limit

		if start > len(tournamentDetails) {
			tournamentDetails = []*model.TournamentDetails{}
		} else if end > len(tournamentDetails) {
			tournamentDetails = tournamentDetails[start:]
		} else {
			tournamentDetails = tournamentDetails[start:end]
		}

		c.JSON(http.StatusOK, gin.H{
			"tournaments": tournamentDetails,
			"page":        page,
			"limit":       limit,
			"total":       len(tournamentDetails),
		})
	}
}

// GetTournamentByID godoc
// @Summary      Get tournament by ID
// @Description  Retrieves a specific tournament by its ID with detailed information
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization header string true  "Bearer JWT token"
// @Param        id  path  string  true  "Tournament ID"
// @Success      200 {object} model.TournamentDetails "Tournament details"
// @Failure      401 {object} object{error=string}    "Authentication required"
// @Failure      404 {object} object{error=string}    "Tournament not found"
// @Failure      500 {object} object{error=string}    "Internal server error"
// @Router       /tournaments/{id} [get]
func GetTournamentByIDHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")

		// Get user ID from authentication middleware (required now)
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		tournamentDetails, err := repo.GetTournamentDetailsByID(tournamentID, &userID)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Tournament not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournament",
			})
			return
		}

		c.JSON(http.StatusOK, tournamentDetails)
	}
}

// UpdateTournament godoc
// @Summary      Update tournament
// @Description  Updates an existing tournament (only recruiter host can update)
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string                    true  "Bearer JWT token"
// @Param        id            path    string                    true  "Tournament ID"
// @Param        tournament    body    UpdateTournamentRequest   true  "Tournament update data"
// @Success      200           {object} model.Tournament          "Tournament updated successfully"
// @Failure      400           {object} object{error=string}      "Invalid input data"
// @Failure      401           {object} object{error=string}      "Authentication required"
// @Failure      403           {object} object{error=string}      "Only recruiters can update tournaments or not authorized to update this tournament"
// @Failure      404           {object} object{error=string}      "Tournament not found"
// @Failure      500           {object} object{error=string}      "Internal server error"
// @Router       /tournaments/{id} [put]
func UpdateTournamentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")

		var req UpdateTournamentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format: " + err.Error(),
			})
			return
		}

		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Check if tournament exists and user is the host
		existingTournament, err := repo.GetTournamentByID(tournamentID)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Tournament not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournament",
			})
			return
		}

		if existingTournament.HostId != userID {
			c.JSON(http.StatusForbidden, gin.H{
				"error": "Not authorized to update this tournament",
			})
			return
		}

		// Update only provided fields
		if req.Title != "" {
			existingTournament.Title = req.Title
		}
		if req.Description != nil {
			existingTournament.Description = req.Description
		}
		if req.Location != "" {
			existingTournament.Location = req.Location
		}
		if req.SportId != "" {
			existingTournament.SportId = req.SportId
		}
		if req.MinAge != nil {
			existingTournament.MinAge = req.MinAge
		}
		if req.MaxAge != nil {
			existingTournament.MaxAge = req.MaxAge
		}
		if req.Level != nil {
			existingTournament.Level = req.Level
		}
		if req.Gender != nil {
			existingTournament.Gender = req.Gender
		}
		if req.Country != nil {
			existingTournament.Country = req.Country
		}
		if req.Status != nil {
			existingTournament.Status = req.Status
		}
		if req.StartDate != "" {
			existingTournament.StartDate = req.StartDate
		}
		if req.EndDate != "" {
			existingTournament.EndDate = req.EndDate
		}
		if req.BannerUrl != nil {
			existingTournament.BannerUrl = req.BannerUrl
		}

		err = repo.UpdateTournament(existingTournament)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to update tournament",
			})
			return
		}

		c.JSON(http.StatusOK, existingTournament)
	}
}

// DeleteTournament godoc
// @Summary      Delete tournament
// @Description  Deletes a tournament (only recruiter host can delete)
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string                true  "Bearer JWT token"
// @Param        id            path    string                true  "Tournament ID"
// @Success      200           {object} object{message=string} "Tournament deleted successfully"
// @Failure      401           {object} object{error=string}   "Authentication required"
// @Failure      403           {object} object{error=string}   "Only recruiters can delete tournaments or not authorized to delete this tournament"
// @Failure      404           {object} object{error=string}   "Tournament not found"
// @Failure      500           {object} object{error=string}   "Internal server error"
// @Router       /tournaments/{id} [delete]
func DeleteTournamentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")

		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Check if tournament exists and user is the host
		tournament, err := repo.GetTournamentByID(tournamentID)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Tournament not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournament",
			})
			return
		}

		if tournament.HostId != userID {
			c.JSON(http.StatusForbidden, gin.H{
				"error": "Not authorized to delete this tournament",
			})
			return
		}

		err = repo.DeleteTournament(tournamentID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to delete tournament",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Tournament deleted successfully",
		})
	}
}

// JoinTournament godoc
// @Summary      Join tournament
// @Description  Allows a user to join a tournament as a participant
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string                 true  "Bearer JWT token"
// @Param        request       body    JoinTournamentRequest  true  "Join tournament request"
// @Success      201           {object} object{message=string}  "Successfully joined tournament"
// @Failure      400           {object} object{error=string}    "Invalid request or already joined"
// @Failure      401           {object} object{error=string}    "Authentication required"
// @Failure      404           {object} object{error=string}    "Tournament not found"
// @Failure      500           {object} object{error=string}    "Internal server error"
// @Router       /tournaments/join [post]
func JoinTournamentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		fmt.Printf("DEBUG: JoinTournamentHandler called\n")

		// Get tournament_id from form or JSON
		var tournamentId string
		if c.GetHeader("Content-Type") == "application/json" {
			var req JoinTournamentRequest
			if err := c.ShouldBindJSON(&req); err != nil {
				fmt.Printf("DEBUG: JSON binding error: %v\n", err)
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Invalid request format: " + err.Error(),
				})
				return
			}
			tournamentId = req.TournamentId
		} else {
			// Handle form data
			tournamentId = c.PostForm("tournament_id")
			if tournamentId == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "tournament_id is required",
				})
				return
			}
		}

		fmt.Printf("DEBUG: Tournament ID: '%s'\n", tournamentId)

		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			fmt.Printf("DEBUG: User not authenticated\n")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Check if tournament exists
		_, err := repo.GetTournamentByID(tournamentId)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Tournament not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournament",
			})
			return
		}

		// Check if user is already a participant
		_, err = repo.GetParticipantByUserAndTournament(userID, tournamentId)
		if err == nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "You are already registered for this tournament",
			})
			return
		}

		// Create participant record
		participant := &model.TounramentParticipants{
			UserId:       userID,
			TournamentId: tournamentId,
			Status:       model.Pending,
		}

		// Debug logging
		fmt.Printf("DEBUG: JoinTournament participant data:\n")
		fmt.Printf("  UserID: '%s'\n", userID)
		fmt.Printf("  TournamentID: '%s'\n", tournamentId)
		fmt.Printf("  Status: '%s'\n", model.Pending)

		err = repo.AddTournamentParticipant(participant)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to join tournament",
			})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "Successfully joined tournament. Your participation is pending approval.",
		})
	}
}

// LeaveTournament godoc
// @Summary      Leave tournament
// @Description  Allows a user to leave a tournament
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string  true  "Bearer JWT token"
// @Param        id            path    string  true  "Tournament ID"
// @Success      200           {object} object{message=string} "Successfully left tournament"
// @Failure      401           {object} object{error=string}   "Authentication required"
// @Failure      404           {object} object{error=string}   "Tournament or participation not found"
// @Failure      500           {object} object{error=string}   "Internal server error"
// @Router       /tournaments/{id}/leave [delete]
func LeaveTournamentHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")

		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		err := repo.RemoveTournamentParticipant(userID, tournamentID)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "You are not registered for this tournament",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to leave tournament",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Successfully left tournament",
		})
	}
}

// GetTournamentParticipants godoc
// @Summary      Get tournament participants
// @Description  Retrieves all participants for a tournament with optional status filtering
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Param        id      path   string  true   "Tournament ID"
// @Param        status  query  string  false  "Filter by participation status" Enums(pending,accepted,rejected)
// @Success      200     {array}  model.TounramentParticipants  "List of participants"
// @Failure      404     {object} object{error=string}          "Tournament not found"
// @Failure      500     {object} object{error=string}          "Internal server error"
// @Router       /tournaments/{id}/participants [get]
func GetTournamentParticipantsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")
		statusStr := c.Query("status")

		var participants []*model.TounramentParticipants
		var err error

		if statusStr != "" {
			status := model.ParticipationStatus(statusStr)
			participants, err = repo.GetTournamentParticipantsByStatus(tournamentID, status)
		} else {
			participants, err = repo.GetTournamentParticipants(tournamentID)
		}

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve participants",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"participants": participants,
		})
	}
}

// UpdateParticipantStatus godoc
// @Summary      Update participant status
// @Description  Updates the status of a tournament participant (only recruiter host can update)
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string                          true  "Bearer JWT token"
// @Param        id            path    string                          true  "Tournament ID"
// @Param        request       body    UpdateParticipantStatusRequest  true  "Status update request"
// @Success      200           {object} object{message=string}          "Participant status updated successfully"
// @Failure      400           {object} object{error=string}            "Invalid request"
// @Failure      401           {object} object{error=string}            "Authentication required"
// @Failure      403           {object} object{error=string}            "Only recruiters can manage tournament participants or not authorized to update participants"
// @Failure      404           {object} object{error=string}            "Tournament or participant not found"
// @Failure      500           {object} object{error=string}            "Internal server error"
// @Router       /tournaments/{id}/participants/status [put]
func UpdateParticipantStatusHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		tournamentID := c.Param("id")

		var req UpdateParticipantStatusRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format: " + err.Error(),
			})
			return
		}

		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Check if tournament exists and user is the host
		tournament, err := repo.GetTournamentByID(tournamentID)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Tournament not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve tournament",
			})
			return
		}

		if tournament.HostId != userID {
			c.JSON(http.StatusForbidden, gin.H{
				"error": "Not authorized to update participants for this tournament",
			})
			return
		}

		err = repo.UpdateParticipantStatus(req.UserId, tournamentID, req.Status)
		if err != nil {
			if err == db.ITEM_NOT_FOUND {
				c.JSON(http.StatusNotFound, gin.H{
					"error": "Participant not found",
				})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to update participant status",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Participant status updated successfully",
		})
	}
}

// GetUserTournaments godoc
// @Summary      Get user tournaments
// @Description  Retrieves all tournaments the authenticated user is participating in
// @Tags         tournaments
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string  true  "Bearer JWT token"
// @Param        status        query   string  false "Filter by participation status" Enums(pending,accepted,rejected)
// @Success      200           {array}  model.TounramentParticipants  "List of user's tournament participations"
// @Failure      401           {object} object{error=string}           "Authentication required"
// @Failure      500           {object} object{error=string}           "Internal server error"
// @Router       /tournaments/my-tournaments [get]
func GetUserTournamentsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		tournaments, err := repo.GetUserTournaments(userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to retrieve user tournaments",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"tournaments": tournaments,
		})
	}
}

// RegisterTournamentRoutes registers all tournament-related routes
func RegisterTournamentRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository, s3Service *services.S3Service) {
	// Initialize JWT middleware
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)

	// Public routes (no authentication required) - only participants list doesn't need user context
	rg.GET("/tournaments/:id/participants", GetTournamentParticipantsHandler(repo))

	// Protected routes (authentication required)
	protected := rg.Group("/")
	protected.Use(jwtMiddleware.AuthMiddleware())
	{
		// Public tournament viewing routes - moved here to get user context for IsEnrolled
		protected.GET("/tournaments", GetTournamentsHandler(repo))
		protected.GET("/tournaments/:id", GetTournamentByIDHandler(repo))

		// Tournament management
		protected.POST("/tournaments", CreateTournamentHandler(repo, s3Service))
		protected.PUT("/tournaments/:id", UpdateTournamentHandler(repo))
		protected.DELETE("/tournaments/:id", DeleteTournamentHandler(repo))

		// Participation management
		protected.POST("/tournaments/join", JoinTournamentHandler(repo))
		protected.DELETE("/tournaments/:id/leave", LeaveTournamentHandler(repo))
		protected.PUT("/tournaments/:id/participants/status", UpdateParticipantStatusHandler(repo))
		protected.GET("/tournaments/my-tournaments", GetUserTournamentsHandler(repo))
	}
}
