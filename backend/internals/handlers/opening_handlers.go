package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
)

// Request/Response models for Opening API
type AddressRequest struct {
	Country    string `json:"country" binding:"required"`
	State      string `json:"state" binding:"required"`
	City       string `json:"city" binding:"required"`
	Street     string `json:"street" binding:"required"`
	Building   string `json:"building" binding:"required"`
	PostalCode string `json:"postal_code" binding:"required"`
}

type CreateOpeningRequest struct {
	CompanyName        string              `json:"company_name" binding:"required"`
	Title              string              `json:"title" binding:"required"`
	Description        string              `json:"description" binding:"required"`
	Position           string              `json:"position" binding:"required"`
	SportName          string              `json:"sport_name" binding:"required"`
	Status             model.OpeningStatus `json:"status" binding:"required"`
	MinAge             *int                `json:"min_age,omitempty"`
	MaxAge             *int                `json:"max_age,omitempty"`
	MinLevel           *string             `json:"min_level,omitempty"`
	MinSalary          *int                `json:"min_salary,omitempty"`
	MaxSalary          *int                `json:"max_salary,omitempty"`
	CountryRestriction *string             `json:"country_restriction,omitempty"`
	Stats              any                 `json:"stats,omitempty"`
	Address            AddressRequest      `json:"address" binding:"required"`
}

type UpdateOpeningRequest struct {
	CompanyName        string              `json:"company_name" binding:"required"`
	Title              string              `json:"title" binding:"required"`
	Description        string              `json:"description" binding:"required"`
	Position           string              `json:"position" binding:"required"`
	SportName          string              `json:"sport_name" binding:"required"`
	Status             model.OpeningStatus `json:"status" binding:"required"`
	MinAge             *int                `json:"min_age,omitempty"`
	MaxAge             *int                `json:"max_age,omitempty"`
	MinLevel           *string             `json:"min_level,omitempty"`
	MinSalary          *int                `json:"min_salary,omitempty"`
	MaxSalary          *int                `json:"max_salary,omitempty"`
	CountryRestriction *string             `json:"country_restriction,omitempty"`
	Stats              any                 `json:"stats,omitempty"`
	Address            AddressRequest      `json:"address" binding:"required"`
}

type OpeningResponse struct {
	ID                 string                   `json:"id"`
	CompanyName        string                   `json:"company_name"`
	Title              string                   `json:"title"`
	Description        string                   `json:"description"`
	Position           string                   `json:"position"`
	SportName          string                   `json:"sport_name"`
	Status             model.OpeningStatus      `json:"status"`
	MinAge             *int                     `json:"min_age,omitempty"`
	MaxAge             *int                     `json:"max_age,omitempty"`
	MinLevel           *string                  `json:"min_level,omitempty"`
	MinSalary          *int                     `json:"min_salary,omitempty"`
	MaxSalary          *int                     `json:"max_salary,omitempty"`
	CountryRestriction *string                  `json:"country_restriction,omitempty"`
	Stats              any                      `json:"stats,omitempty"`
	Address            model.SAddress           `json:"address"`
	CreatedAt          string                   `json:"created_at"`
	UpdatedAt          string                   `json:"updated_at"`
	Applied            bool                     `json:"applied"`
	ApplicationStatus  *model.ApplicationStatus `json:"application_status,omitempty"`
}

// SingleOpeningResponse for swagger documentation
type SingleOpeningResponse struct {
	Opening OpeningResponse `json:"opening"`
}

// MultipleOpeningsResponse for swagger documentation
type MultipleOpeningsResponse struct {
	Openings []OpeningResponse `json:"openings"`
}

type UpdateOpeningStatusRequest struct {
	Status model.OpeningStatus `json:"status" binding:"required"`
}

// Helper function to convert AddressRequest to model.SAddress
func toSAddress(req AddressRequest) *model.SAddress {
	return &model.SAddress{
		Country:    req.Country,
		State:      req.State,
		City:       req.City,
		Street:     req.Street,
		Building:   req.Building,
		PostalCode: req.PostalCode,
	}
}

// Helper function to convert OpeningDetails to OpeningResponse
func toOpeningResponse(openingDetails *model.OpeningDetails) *OpeningResponse {
	return &OpeningResponse{
		ID:                 openingDetails.Opening.Id,
		CompanyName:        openingDetails.Opening.CompanyName,
		Title:              openingDetails.Opening.Title,
		Description:        openingDetails.Opening.Description,
		Position:           openingDetails.Opening.Position,
		SportName:          openingDetails.SportName,
		Status:             openingDetails.Opening.Status,
		MinAge:             openingDetails.Opening.MinAge,
		MaxAge:             openingDetails.Opening.MaxAge,
		MinLevel:           openingDetails.Opening.MinLevel,
		MinSalary:          openingDetails.Opening.MinSalary,
		MaxSalary:          openingDetails.Opening.MaxSalary,
		CountryRestriction: openingDetails.Opening.CountryRestriction,
		Stats:              openingDetails.Opening.Stats,
		Address:            *openingDetails.Address,
		CreatedAt:          openingDetails.Opening.CreatedAt,
		UpdatedAt:          openingDetails.Opening.UpdatedAt,
		Applied:            openingDetails.Applied,
		ApplicationStatus:  openingDetails.ApplicationStatus,
	}
}

// CreateOpening godoc
// @Summary      Create a new job opening
// @Description  Creates a new job opening for the authenticated recruiter
// @Tags         openings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        opening  body      CreateOpeningRequest  true  "Opening details"
// @Success      201      {object}  SingleOpeningResponse
// @Failure      400      {object}  map[string]string
// @Failure      401      {object}  map[string]string
// @Failure      403      {object}  map[string]string
// @Failure      500      {object}  map[string]string
// @Router       /openings [post]
func CreateOpeningHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Parse request
		var req CreateOpeningRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		// Validate opening status
		if req.Status != model.OpeningStatusOpen && req.Status != model.OpeningStatusClosed {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid opening status"})
			return
		}

		// Create opening model
		opening := &model.Opening{
			RecruiterID:        userID,
			CompanyName:        req.CompanyName,
			Title:              req.Title,
			Description:        req.Description,
			Position:           req.Position,
			Status:             req.Status,
			MinAge:             req.MinAge,
			MaxAge:             req.MaxAge,
			MinLevel:           req.MinLevel,
			MinSalary:          req.MinSalary,
			MaxSalary:          req.MaxSalary,
			CountryRestriction: req.CountryRestriction,
			Stats:              req.Stats,
		}

		// Create opening in database
		openingID, err := repo.CreateOpening(opening, toSAddress(req.Address), req.SportName)
		if err != nil {
			log.Println(err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get the created opening details
		openingDetails, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			log.Println(err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusCreated, gin.H{"opening": toOpeningResponse(openingDetails)})
	}
}

// UpdateOpening godoc
// @Summary      Update a job opening
// @Description  Updates an existing job opening. Only the owner (recruiter) can update the opening.
// @Tags         openings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id       path      string                true  "Opening ID"
// @Param        opening  body      UpdateOpeningRequest  true  "Updated opening details"
// @Success      200      {object}  SingleOpeningResponse
// @Failure      400      {object}  map[string]string
// @Failure      401      {object}  map[string]string
// @Failure      403      {object}  map[string]string
// @Failure      404      {object}  map[string]string
// @Failure      500      {object}  map[string]string
// @Router       /openings/{id} [put]
func UpdateOpeningHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Get opening ID from URL
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Check if opening exists and get current details
		existingOpening, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user is the owner of the opening
		if existingOpening.Opening.RecruiterID != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own openings"})
			return
		}

		// Parse request
		var req UpdateOpeningRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		// Validate opening status
		if req.Status != model.OpeningStatusOpen && req.Status != model.OpeningStatusClosed {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid opening status"})
			return
		}

		// Create updated opening details
		updatedOpening := &model.OpeningDetails{
			Opening: &model.Opening{
				AppModel: model.AppModel{
					Id: openingID,
				},
				RecruiterID:        userID,
				CompanyName:        req.CompanyName,
				Title:              req.Title,
				Description:        req.Description,
				Position:           req.Position,
				Status:             req.Status,
				MinAge:             req.MinAge,
				MaxAge:             req.MaxAge,
				MinLevel:           req.MinLevel,
				MinSalary:          req.MinSalary,
				MaxSalary:          req.MaxSalary,
				CountryRestriction: req.CountryRestriction,
				Stats:              req.Stats,
				AddressID:          existingOpening.Opening.AddressID,
			},
			SportName: req.SportName,
			Address:   toSAddress(req.Address),
		}

		// Ensure the address ID is preserved
		updatedOpening.Address.Id = existingOpening.Address.Id

		// Update opening in database
		if err := repo.UpdateOpening(updatedOpening); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get the updated opening details
		openingDetails, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"opening": toOpeningResponse(openingDetails)})
	}
}

// DeleteOpening godoc
// @Summary      Delete a job opening
// @Description  Deletes an existing job opening. Only the owner (recruiter) can delete the opening.
// @Tags         openings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "Opening ID"
// @Success      200 {object}  map[string]string
// @Failure      400 {object}  map[string]string
// @Failure      401 {object}  map[string]string
// @Failure      403 {object}  map[string]string
// @Failure      404 {object}  map[string]string
// @Failure      500 {object}  map[string]string
// @Router       /openings/{id} [delete]
func DeleteOpeningHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Get opening ID from URL
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Check if opening exists and get current details
		existingOpening, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user is the owner of the opening
		if existingOpening.Opening.RecruiterID != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own openings"})
			return
		}

		// Delete opening from database
		if err := repo.DeleteOpening(openingID); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Opening deleted successfully"})
	}
}

// UpdateOpeningStatus godoc
// @Summary      Update opening status
// @Description  Updates the status of a job opening (open/closed). Only the owner (recruiter) can update the status.
// @Tags         openings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id      path  string                      true  "Opening ID"
// @Param        status  body  UpdateOpeningStatusRequest  true  "New status"
// @Success      200     {object}  SingleOpeningResponse
// @Failure      400     {object}  map[string]string
// @Failure      401     {object}  map[string]string
// @Failure      403     {object}  map[string]string
// @Failure      404     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Router       /openings/{id}/status [patch]
func UpdateOpeningStatusHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Get opening ID from URL
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Check if opening exists and get current details
		existingOpening, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Check if user is the owner of the opening
		if existingOpening.Opening.RecruiterID != userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "You can only update your own openings"})
			return
		}

		// Parse request
		var req UpdateOpeningStatusRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		// Validate opening status
		if req.Status != model.OpeningStatusOpen && req.Status != model.OpeningStatusClosed {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid opening status"})
			return
		}

		// Update opening status in database
		if err := repo.UpdateOpeningStatus(openingID, req.Status); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Get the updated opening details
		openingDetails, err := repo.GetOpeningByID(openingID, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"opening": toOpeningResponse(openingDetails)})
	}
}

// GetOpeningByID godoc
// @Summary      Get opening by ID
// @Description  Retrieves a specific job opening by its ID
// @Tags         openings
// @Accept       json
// @Produce      json
// @Param        id  path  string  true  "Opening ID"
// @Success      200 {object}  SingleOpeningResponse
// @Failure      400 {object}  map[string]string
// @Failure      404 {object}  map[string]string
// @Failure      500 {object}  map[string]string
// @Router       /openings/{id} [get]
func GetOpeningByIDHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get opening ID from URL
		openingID := c.Param("id")
		if openingID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Opening ID is required"})
			return
		}

		// Try to get user ID and role from authentication middleware (optional)
		var playerID *string
		if userID, exists := middleware.GetUserIDFromContext(c); exists && userID != "" {
			if role, roleExists := middleware.GetRoleFromContext(c); roleExists && role == "player" {
				playerID = &userID
			}
			// If user is recruiter, playerID remains nil
		}

		// Get opening from database
		openingDetails, err := repo.GetOpeningByID(openingID, playerID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"opening": toOpeningResponse(openingDetails)})
	}
}

// GetOpenings godoc
// @Summary      Get all openings
// @Description  Retrieves all job openings with pagination
// @Tags         openings
// @Accept       json
// @Produce      json
// @Param        limit   query  int     false  "Number of openings to return (default: 10)"
// @Param        offset  query  int     false  "Number of openings to skip (default: 0)"
// @Success      200     {object}  MultipleOpeningsResponse
// @Failure      400     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Router       /openings [get]
func GetAllOpeningsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse pagination parameters
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid limit parameter"})
			return
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offset parameter"})
			return
		}

		// Try to get user ID and role from authentication middleware (optional)
		var playerID *string
		if userID, exists := middleware.GetUserIDFromContext(c); exists && userID != "" {
			if role, roleExists := middleware.GetRoleFromContext(c); roleExists && role == "player" {
				playerID = &userID
			}
			// If user is recruiter, playerID remains nil
		}

		// Get openings from database
		openingDetailsList, err := repo.GetAllOpenings(limit, offset, playerID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Convert to response format
		// var responses []OpeningResponse
		responses := make([]OpeningResponse, 0)
		for _, openingDetails := range openingDetailsList {
			responses = append(responses, *toOpeningResponse(openingDetails))
		}

		c.JSON(http.StatusOK, gin.H{"openings": responses})
	}
}

// GetOpeningsByRecruiter godoc
// @Summary      Get openings by recruiter
// @Description  Retrieves all job openings created by the authenticated recruiter
// @Tags         openings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query  int     false  "Number of openings to return (default: 10)"
// @Param        offset  query  int     false  "Number of openings to skip (default: 0)"
// @Success      200     {object}  MultipleOpeningsResponse
// @Failure      400     {object}  map[string]string
// @Failure      401     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Router       /openings/my [get]
func GetOpeningsByRecruiterHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user ID from authentication middleware
		userID, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		// Parse pagination parameters
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid limit parameter"})
			return
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offset parameter"})
			return
		}

		// Get openings from database
		openingDetailsList, err := repo.GetOpeningsByRecruiterID(userID, limit, offset, nil)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		responses := make([]OpeningResponse, 0)
		for _, openingDetails := range openingDetailsList {
			responses = append(responses, *toOpeningResponse(openingDetails))
		}

		c.JSON(http.StatusOK, gin.H{"openings": responses})
	}
}

// GetOpeningsBySport godoc
// @Summary      Get openings by sport
// @Description  Retrieves all job openings for a specific sport
// @Tags         openings
// @Accept       json
// @Produce      json
// @Param        sport   path   string  true   "Sport name"
// @Param        limit   query  int     false  "Number of openings to return (default: 10)"
// @Param        offset  query  int     false  "Number of openings to skip (default: 0)"
// @Success      200     {object}  MultipleOpeningsResponse
// @Failure      400     {object}  map[string]string
// @Failure      500     {object}  map[string]string
// @Router       /openings/sport/{sport} [get]
func GetOpeningsBySportHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get sport name from URL
		sportName := c.Param("sport")
		if sportName == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Sport name is required"})
			return
		}

		// Parse pagination parameters
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid limit parameter"})
			return
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offset parameter"})
			return
		}

		// Try to get user ID and role from authentication middleware (optional)
		var playerID *string
		if userID, exists := middleware.GetUserIDFromContext(c); exists && userID != "" {
			if role, roleExists := middleware.GetRoleFromContext(c); roleExists && role == "player" {
				playerID = &userID
			}
			// If user is recruiter, playerID remains nil
		}

		// Get openings from database
		openingDetailsList, err := repo.GetOpeningsBySport(sportName, limit, offset, playerID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Convert to response format
		responses := make([]OpeningResponse, 0)
		for _, openingDetails := range openingDetailsList {
			responses = append(responses, *toOpeningResponse(openingDetails))
		}

		c.JSON(http.StatusOK, gin.H{"openings": responses})
	}
}

// GetOpeningsByFilter godoc
// @Summary      Get openings by filter
// @Description  Retrieves job openings filtered by various criteria
// @Tags         openings
// @Accept       json
// @Produce      json
// @Param        sport_name          query  string  false  "Sport name"
// @Param        status              query  string  false  "Opening status (open/closed)"
// @Param        min_age             query  int     false  "Minimum age requirement"
// @Param        max_age             query  int     false  "Maximum age requirement"
// @Param        min_salary          query  int     false  "Minimum salary expectation"
// @Param        max_salary          query  int     false  "Maximum salary expectation"
// @Param        country_restriction query  string  false  "Country restriction"
// @Param        country             query  string  false  "Country (location)"
// @Param        state               query  string  false  "State (location)"
// @Param        city                query  string  false  "City (location)"
// @Param        company_name        query  string  false  "Company name"
// @Param        position            query  string  false  "Position title"
// @Param        applied             query  bool    false  "Filter by application status (requires authentication)"
// @Param        limit               query  int     false  "Number of openings to return (default: 10)"
// @Param        offset              query  int     false  "Number of openings to skip (default: 0)"
// @Success      200                 {object}  MultipleOpeningsResponse
// @Failure      400                 {object}  map[string]string
// @Failure      500                 {object}  map[string]string
// @Router       /openings/filter [get]
func GetOpeningsByFilterHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse pagination parameters
		limitStr := c.DefaultQuery("limit", "10")
		offsetStr := c.DefaultQuery("offset", "0")

		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid limit parameter"})
			return
		}

		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid offset parameter"})
			return
		}

		// Build filter from query parameters
		filter := &repositories.OpeningFilter{}

		if sportName := c.Query("sport_name"); sportName != "" {
			filter.SportName = &sportName
		}

		if statusStr := c.Query("status"); statusStr != "" {
			status := model.OpeningStatus(statusStr)
			if status != model.OpeningStatusOpen && status != model.OpeningStatusClosed {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status parameter. Must be 'open' or 'closed'"})
				return
			}
			filter.Status = &status
		}

		if minAgeStr := c.Query("min_age"); minAgeStr != "" {
			minAge, err := strconv.Atoi(minAgeStr)
			if err != nil || minAge < 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid min_age parameter"})
				return
			}
			filter.MinAge = &minAge
		}

		if maxAgeStr := c.Query("max_age"); maxAgeStr != "" {
			maxAge, err := strconv.Atoi(maxAgeStr)
			if err != nil || maxAge < 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid max_age parameter"})
				return
			}
			filter.MaxAge = &maxAge
		}

		if minSalaryStr := c.Query("min_salary"); minSalaryStr != "" {
			minSalary, err := strconv.Atoi(minSalaryStr)
			if err != nil || minSalary < 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid min_salary parameter"})
				return
			}
			filter.MinSalary = &minSalary
		}

		if maxSalaryStr := c.Query("max_salary"); maxSalaryStr != "" {
			maxSalary, err := strconv.Atoi(maxSalaryStr)
			if err != nil || maxSalary < 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid max_salary parameter"})
				return
			}
			filter.MaxSalary = &maxSalary
		}

		if countryRestriction := c.Query("country_restriction"); countryRestriction != "" {
			filter.CountryRestriction = &countryRestriction
		}

		if country := c.Query("country"); country != "" {
			filter.Country = &country
		}

		if state := c.Query("state"); state != "" {
			filter.State = &state
		}

		if city := c.Query("city"); city != "" {
			filter.City = &city
		}

		if companyName := c.Query("company_name"); companyName != "" {
			filter.CompanyName = &companyName
		}

		if position := c.Query("position"); position != "" {
			filter.Position = &position
		}

		if appliedStr := c.Query("applied"); appliedStr != "" {
			switch appliedStr {
			case "true":
				applied := true
				filter.Applied = &applied
			case "false":
				applied := false
				filter.Applied = &applied
			default:
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid applied parameter. Must be 'true' or 'false'"})
				return
			}
		}

		// Try to get user ID and role from authentication middleware (optional)
		var playerID *string
		if userID, exists := middleware.GetUserIDFromContext(c); exists && userID != "" {
			if role, roleExists := middleware.GetRoleFromContext(c); roleExists && role == "player" {
				playerID = &userID
			}
			// If user is recruiter, playerID remains nil
		}

		// Get openings from database
		openingDetailsList, err := repo.GetOpeningsByFilter(filter, limit, offset, playerID)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		responses := make([]OpeningResponse, 0)
		for _, openingDetails := range openingDetailsList {
			responses = append(responses, *toOpeningResponse(openingDetails))
		}

		c.JSON(http.StatusOK, gin.H{"openings": responses})
	}
}

// RegisterOpeningRoutes registers all opening-related routes
func RegisterOpeningRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository) {
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)
	protected := rg.Group("/")
	protected.Use(jwtMiddleware.AuthMiddleware())
	{
		protected.GET("/openings", GetAllOpeningsHandler(repo))
		protected.GET("/openings/:id", GetOpeningByIDHandler(repo))
		protected.GET("/openings/sport/:sport", GetOpeningsBySportHandler(repo))
		protected.GET("/openings/filter", GetOpeningsByFilterHandler(repo))
		protected.POST("/openings", CreateOpeningHandler(repo))
		protected.PUT("/openings/:id", UpdateOpeningHandler(repo))
		protected.DELETE("/openings/:id", DeleteOpeningHandler(repo))
		protected.PATCH("/openings/:id/status", UpdateOpeningStatusHandler(repo))

		protected.GET("/openings/my", GetOpeningsByRecruiterHandler(repo))

		// Application routes
		protected.POST("/openings/:id/apply", CreateApplicationHandler(repo))
		protected.GET("/openings/:id/applicants", GetApplicantsByOpeningIDHandler(repo))
		protected.PATCH("/openings/:id/applicants/:applicant_id/accept", AcceptApplicationHandler(repo))
		protected.PATCH("/openings/:id/applicants/:applicant_id/reject", RejectApplicationHandler(repo))
		protected.PATCH("/openings/:id/applicants/:applicant_id/withdraw", WithdrawApplicationHandler(repo))
	}
}
