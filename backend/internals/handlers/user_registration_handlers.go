package handlers

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
	"sportsin_backend/internals/utils"
)

type ProfileCreateRequest struct {
	ProfilePicture   string `json:"profile_picture" example:"https://example.com/avatar.jpg"`
	UserName         string `json:"user_name" binding:"required" example:"john_player123"`
	Name             string `json:"name" binding:"required" example:"John"`
	MiddleName       string `json:"middle_name" example:"Michael"`
	Surname          string `json:"surname" binding:"required" example:"Doe"`
	DOB              string `json:"dob" binding:"required" example:"1995-06-15"`
	Gender           string `json:"gender" binding:"required" example:"male" enums:"male,female,other,rather_not_say"`
	About            string `json:"about" example:"Passionate football player with 10 years of experience"`
	Level            string `json:"level" example:"state" enums:"district,state,country,international,personal"`
	InterestLevel    string `json:"interest_level" example:"international" enums:"district,state,country,international,personal"`
	InterestCountry  string `json:"interest_country" example:"United States"`
	OrganizationName string `json:"organization_name" example:"Sports Academy Inc"`
	OrganizationId   string `json:"organization_id" example:"SA-12345"`
	PhoneNumber      string `json:"phone_number" example:"+1234567890"`
	Position         string `json:"position" example:"Head Scout"`
	ReferalCode      string `json:"referal_code" example:"1234567890"`
}

type ProfileUpdateRequest struct {
	ProfilePicture   string `json:"profile_picture" example:"https://example.com/new-avatar.jpg"`
	Name             string `json:"name" example:"John"`
	MiddleName       string `json:"middle_name" example:"Michael"`
	Surname          string `json:"surname" example:"Doe"`
	DOB              string `json:"dob" example:"1995-06-15"`
	Gender           string `json:"gender" example:"male" enums:"male,female,other,rather_not_say"`
	About            string `json:"about" example:"Updated bio - Passionate football player"`
	Level            string `json:"level" example:"country" enums:"district,state,country,international,personal"`
	InterestLevel    string `json:"interest_level" example:"international" enums:"district,state,country,international,personal"`
	InterestCountry  string `json:"interest_country" example:"Canada"`
	OrganizationName string `json:"organization_name" example:"New Sports Academy"`
	OrganizationId   string `json:"organization_id" example:"NSA-67890"`
	PhoneNumber      string `json:"phone_number" example:"+1987654321"`
	Position         string `json:"position" example:"Senior Scout"`
}

type DeviceTokenRequest struct {
	DeviceToken string `json:"device_token" binding:"required"`
	SnsEndpoint string `json:"sns_endpoint" binding:"required"`
}

// CreateProfile godoc
// @Summary      Create user profile
// @Description  Creates a detailed profile for the authenticated user. Required fields vary by role: players need level and interest_level, recruiters need organization details and phone number.
// @Tags         Profile Management
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization        header  string                    true   "Bearer JWT token"
// @Param        profileCreateRequest body    ProfileCreateRequest      true   "Profile creation data with role-specific requirements"
// @Success      201                  {object} object{message=string,user_id=string}  "Profile created successfully"
// @Failure      400                  {object} object{error=string}                   "Invalid input data, role, or missing required fields"
// @Failure      401                  {object} object{error=string}                   "Authentication required"
// @Failure      409                  {object} object{error=string}                   "Profile already exists"
// @Failure      500                  {object} object{error=string}                   "Internal server error"
// @Router       /profile [post]
func CreateProfileHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ProfileCreateRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format",
			})
			return
		}

		// Get user email from authenticated context
		userId, exists := middleware.GetUserIDFromContext(c)
		log.Println("Got user ID", userId)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		roleStr, exists := middleware.GetRoleFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		role, err := model.ParseRole(roleStr)
		if err != nil {
			log.Println("Invalid role Associated with user")
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid role Associated with user",
			})
		}

		if role != model.PlayerRole && role != model.RecruiterRole {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid role. Must be 'player' or 'recruiter'",
			})
			return
		}

		gender := model.Gender(strings.ToLower(req.Gender))
		if gender != model.Male && gender != model.Female && gender != model.Other && gender != model.RatherNotSay {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid gender. Must be 'male', 'female', 'other', or 'rather_not_say'",
			})
			return
		}

		if req.ReferalCode != "" {
			referalCodeExists, err := repo.ReferalCodeExists(req.ReferalCode)
			if err != nil {
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
			if !referalCodeExists {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Referal code does not exist",
				})
				return
			}
		}

		referralExists := true
		var referalCode string

		for referralExists {
			referalCode = utils.GenerateReferalCode()
			referralExists, err = repo.ReferalCodeExists(referalCode)
			if err != nil {
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
		}

		usernameExists, err := repo.UsernameExists(req.UserName)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		if usernameExists {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Username already exists",
			})
			return
		}

		userDetails := model.UserDetails{
			User: model.User{
				AppModel: model.AppModel{
					Id: userId,
				},
				Role: role,
			},
			UserName:       req.UserName,
			ProfilePicture: &req.ProfilePicture,
			Name:           req.Name,
			MiddleName:     &req.MiddleName,
			Surname:        req.Surname,
			DOB:            req.DOB,
			Gender:         gender,
			About:          &req.About,
			ReferalCode:    &referalCode,
		}

		var profile any

		switch role {
		case model.PlayerRole:
			if req.Level == "" || req.InterestLevel == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Level and interest level are required for player profiles",
				})
				return
			}

			level := model.Level(strings.ToLower(req.Level))
			interestLevel := model.Level(strings.ToLower(req.InterestLevel))

			if !isValidLevel(level) || !isValidLevel(interestLevel) {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Invalid level. Must be 'district', 'state', 'country', 'international', or 'personal'",
				})
				return
			}

			profile = &model.Player{
				UserDetails:     userDetails,
				Level:           level,
				InterestLevel:   interestLevel,
				InterestCountry: &req.InterestCountry,
			}

		case model.RecruiterRole:
			if req.OrganizationName == "" || req.OrganizationId == "" || req.PhoneNumber == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Organization name, organization ID, and phone number are required for recruiter profiles",
				})
				return
			}

			profile = &model.Recruiter{
				UserDetails:      userDetails,
				OrganizationName: req.OrganizationName,
				OrganizationId:   req.OrganizationId,
				PhoneNumber:      req.PhoneNumber,
				Position:         req.Position,
			}

		}

		if err := repo.CreateUserProfile(profile); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		var referalErr string
		if req.ReferalCode != "" {
			if err := repo.ReferUser(userId, req.ReferalCode); err != nil {
				referalErr = "Failed to refer user"
			}
		}

		c.JSON(http.StatusCreated, gin.H{
			"message":       "Profile created successfully",
			"user_id":       userId,
			"referal_error": referalErr,
		})

	}

}

// GetProfile godoc
// @Summary      Get user profile by ID
// @Description  Retrieves a public user profile by user ID. This endpoint is publicly accessible and returns basic profile information.
// @Tags         Profile Management
// @Accept       json
// @Produce      json
// @Param        id   path      string  true  "User ID (UUID format)"
// @Success      200  {object}  object{profile=object}     "User profile data"
// @Failure      400  {object}  object{error=string}       "Invalid or missing user ID"
// @Failure      404  {object}  object{error=string}       "Profile not found"
// @Failure      500  {object}  object{error=string}       "Internal server error"
// @Router       /profile/{id} [get]
func GetProfileHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		userId := c.Param("id")
		if userId == "" {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "User ID is required",
			})
			return
		}

		profile, err := repo.GetUserProfile(userId)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"profile": profile,
		})
	}
}

// GetMyProfile godoc
// @Summary      Get current user's profile
// @Description  Retrieves the complete profile information for the authenticated user, including private details
// @Tags         Profile Management
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization  header  string  true  "Bearer JWT token"
// @Success      200            {object} object{profile=object}     "Current user's complete profile data"
// @Failure      401            {object} object{error=string}       "Authentication required"
// @Failure      404            {object} object{error=string}       "Profile not found"
// @Failure      500            {object} object{error=string}       "Internal server error"
// @Router       /profile/me [get]
func GetMyProfileHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user email from authenticated context
		email, exists := middleware.GetEmailFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Get user information from database using email
		user, err := repo.GetUserByEmail(email)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		profile, err := repo.GetUserProfile(user.Id)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"profile": profile,
		})
	}
}

// UpdateProfile godoc
// @Summary      Update user profile
// @Description  Updates the authenticated user's profile with provided fields. Only non-empty fields will be updated. Role-specific validations apply.
// @Tags         Profile Management
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        Authorization        header  string                    true   "Bearer JWT token"
// @Param        profileUpdateRequest body    ProfileUpdateRequest      true   "Profile update data (only provided fields will be updated)"
// @Success      200                  {object} object{message=string,user_id=string}  "Profile updated successfully"
// @Failure      400                  {object} object{error=string}                   "Invalid input data or validation errors"
// @Failure      401                  {object} object{error=string}                   "Authentication required"
// @Failure      404                  {object} object{error=string}                   "Profile not found"
// @Failure      500                  {object} object{error=string}                   "Internal server error"
// @Router       /profile [put]
func UpdateProfileHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user email from authenticated context
		email, exists := middleware.GetEmailFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		// Get user information from database using email
		user, err := repo.GetUserByEmail(email)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Failed to get user information",
			})
			return
		}

		userId := user.Id

		var req ProfileUpdateRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format",
			})
			return
		}

		// Get existing profile to determine role
		existingProfile, err := repo.GetUserProfile(userId)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		// Validate gender if provided
		var gender model.Gender
		if req.Gender != "" {
			gender = model.Gender(strings.ToLower(req.Gender))
			if gender != model.Male && gender != model.Female && gender != model.Other && gender != model.RatherNotSay {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Invalid gender. Must be 'male', 'female', 'other', or 'rather_not_say'",
				})
				return
			}
		}

		var updatedProfile interface{}

		switch profile := existingProfile.(type) {
		case *model.Player:
			// Update player profile
			if req.Name != "" {
				profile.Name = req.Name
			}
			if req.MiddleName != "" {
				profile.MiddleName = &req.MiddleName
			}
			if req.Surname != "" {
				profile.Surname = req.Surname
			}
			if req.DOB != "" {
				profile.DOB = req.DOB
			}
			if req.Gender != "" {
				profile.Gender = gender
			}
			if req.About != "" {
				profile.About = &req.About
			}
			if req.ProfilePicture != "" {
				profile.ProfilePicture = &req.ProfilePicture
			}
			if req.Level != "" {
				level := model.Level(strings.ToLower(req.Level))
				if !isValidLevel(level) {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "Invalid level. Must be 'district', 'state', 'country', 'international', or 'personal'",
					})
					return
				}
				profile.Level = level
			}
			if req.InterestLevel != "" {
				interestLevel := model.Level(strings.ToLower(req.InterestLevel))
				if !isValidLevel(interestLevel) {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "Invalid interest level. Must be 'district', 'state', 'country', 'international', or 'personal'",
					})
					return
				}
				profile.InterestLevel = interestLevel
			}
			if req.InterestCountry != "" {
				profile.InterestCountry = &req.InterestCountry
			}

			updatedProfile = profile

		case *model.Recruiter:
			// Update recruiter profile
			if req.Name != "" {
				profile.Name = req.Name
			}
			if req.MiddleName != "" {
				profile.MiddleName = &req.MiddleName
			}
			if req.Surname != "" {
				profile.Surname = req.Surname
			}
			if req.DOB != "" {
				profile.DOB = req.DOB
			}
			if req.Gender != "" {
				profile.Gender = gender
			}
			if req.About != "" {
				profile.About = &req.About
			}
			if req.ProfilePicture != "" {
				profile.ProfilePicture = &req.ProfilePicture
			}
			if req.OrganizationName != "" {
				profile.OrganizationName = req.OrganizationName
			}
			if req.OrganizationId != "" {
				profile.OrganizationId = req.OrganizationId
			}
			if req.PhoneNumber != "" {
				profile.PhoneNumber = req.PhoneNumber
			}
			if req.Position != "" {
				profile.Position = req.Position
			}

			updatedProfile = profile

		default:
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Unknown profile type",
			})
			return
		}

		// Update the profile
		if err := repo.UpdateProfile(updatedProfile); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Profile updated successfully",
			"user_id": userId,
		})
	}
}

func GenerateReferalCodeHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		userId, ok := middleware.GetUserIDFromContext(c)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not authenticated"})
			return
		}

		userIdExists, err := repo.UserHasReferalCode(userId)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		if userIdExists {
			referalCode, err := repo.GetReferalCode(userId)
			if err != nil {
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
			c.JSON(http.StatusOK, gin.H{"message": "Referal code already exists", "referal_code": referalCode})
			return
		}

		referalExists := true
		var referalCode string
		for referalExists {
			referalCode = utils.GenerateReferalCode()
			referalExists, err = repo.ReferalCodeExists(referalCode)
			if err != nil {
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
		}

		err = repo.CreateReferalCode(userId, referalCode)
		if err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Referal code generated successfully", "referal_code": referalCode})
	}
}

func RegisterDeviceTokenHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req DeviceTokenRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format",
			})
			return
		}

		userId, exists := middleware.GetUserIDFromContext(c)
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "User not authenticated",
			})
			return
		}

		if err := repo.AddUserDeviceTokenDetails(userId, req.DeviceToken, req.SnsEndpoint); err != nil {
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Device token registered successfully",
		})
	}
}

// RegisterProfileRoutes registers all profile-related routes
func RegisterProfileRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository) {
	jwtMiddleware := middleware.NewJWTMiddleware(cfg)
	r := rg.Group("/profile")

	// Protected routes that require authentication
	protected := r.Group("")
	protected.Use(jwtMiddleware.AuthMiddleware())

	protected.POST("", CreateProfileHandler(repo))
	protected.PUT("", UpdateProfileHandler(repo))
	protected.GET("/me", GetMyProfileHandler(repo))
	protected.GET("/referal", GenerateReferalCodeHandler(repo))
	protected.POST("/device-token", RegisterDeviceTokenHandler(repo))

	// Public route for getting profiles by ID
	r.GET("/:id", GetProfileHandler(repo))
}

// Helper function to validate level values
func isValidLevel(level model.Level) bool {
	switch level {
	case model.DistrictLevel, model.StateLevel, model.CountryLevel, model.InternationalLevel, model.PersonalLevel:
		return true
	default:
		return false
	}
}
