package handlers

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/auth"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/model"
)

// Signup godoc
// @Summary      Register a new user account
// @Description  Creates a new user account in AWS Cognito and stores user information in the database. The user will receive a verification code via email/SMS.
// @Tags         Authentication
// @Accept       json
// @Produce      json
// @Param        signupInput  body     auth.SignupInput  true  "User registration details including email, password, phone (optional), and role"
// @Success      200          {object} object{message=string}                    "Registration successful"
// @Failure      400          {object} object{error=string}                      "Invalid input data or role"
// @Failure      409          {object} object{error=string}                      "User with email already exists"
// @Failure      429          {object} object{error=string}                      "Too many requests, rate limited"
// @Failure      500          {object} object{error=string}                      "Internal server error"
// @Router       /signup [post]
func SignupHandler(svc *auth.CognitoService, repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req auth.SignupInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		if req.Role != model.AdminRole && req.Role != model.RecruiterRole && req.Role != model.PlayerRole {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid role"})
			return
		}

		// First, create user in Cognito
		userId, err := svc.Signup(req)
		if err != nil {
			var userExistsErr *auth.UserExistsError
			var invalidParamErr *auth.InvalidParameterError
			var invalidPasswordErr *auth.InvalidPasswordError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &userExistsErr):
				c.JSON(http.StatusConflict, gin.H{"error": "User with this email already exists"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &invalidPasswordErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Password does not meet requirements"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected signup error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}

		if err := repo.CreateUserOnSignup(userId, req.Email, req.Role); err != nil {
			log.Printf("Failed to create user record in database: %v", err)
			httpErr := db.ToHTTPError(err)
			c.JSON(httpErr.StatusCode, httpErr)
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Signup successful. Please check your email/SMS for the verification code."})
	}
}

func RegisterAuthRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository) {
	svc := auth.NewCognitoService(cfg)
	r := rg.Group("/")

	r.POST("/signup", SignupHandler(svc, repo))

	// Verify godoc
	// @Summary      Verify user account
	// @Description  Confirms user registration using the verification code sent via email/SMS during signup
	// @Tags         Authentication
	// @Accept       json
	// @Produce      json
	// @Param        confirmInput  body     auth.ConfirmInput  true  "Email and verification code"
	// @Success      200           {object} object{message=string}                 "Account verified successfully"
	// @Failure      400           {object} object{error=string}                   "Invalid input, verification code, or expired code"
	// @Failure      404           {object} object{error=string}                   "User not found"
	// @Failure      429           {object} object{error=string}                   "Too many requests, rate limited"
	// @Failure      500           {object} object{error=string}                   "Internal server error"
	// @Router       /verify [post]
	r.POST("/verify", func(c *gin.Context) {
		var req auth.ConfirmInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		if err := svc.Confirm(req); err != nil {
			var userNotFoundErr *auth.UserNotFoundError
			var invalidCodeErr *auth.InvalidCodeError
			var codeExpiredErr *auth.CodeExpiredError
			var invalidParamErr *auth.InvalidParameterError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &userNotFoundErr):
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			case errors.As(err, &invalidCodeErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid verification code"})
			case errors.As(err, &codeExpiredErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Verification code has expired"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected verify error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Account verified. You can now log in."})
	})

	// Forgot Password godoc
	// @Summary      Request password reset
	// @Description  Initiates password reset process by sending a reset code to the user's email address
	// @Tags         Authentication
	// @Accept       json
	// @Produce      json
	// @Param        forgotPasswordInput  body     auth.ForgotPasswordInput  true  "User email address"
	// @Success      200                  {object} object{message=string}                       "Password reset code sent successfully"
	// @Failure      400                  {object} object{error=string}                         "Invalid input provided"
	// @Failure      404                  {object} object{error=string}                         "User not found"
	// @Failure      429                  {object} object{error=string}                         "Too many requests, rate limited"
	// @Failure      500                  {object} object{error=string}                         "Internal server error"
	// @Router       /forgot-password [post]
	r.POST("/forgot-password", func(c *gin.Context) {
		var req auth.ForgotPasswordInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		if err := svc.ForgotPassword(req); err != nil {
			var userNotFoundErr *auth.UserNotFoundError
			var invalidParamErr *auth.InvalidParameterError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &userNotFoundErr):
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected forgot password error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Password reset link sent to your email."})
	})

	// Reset Password godoc
	// @Summary      Reset user password
	// @Description  Completes password reset using the reset code received via email and sets a new password
	// @Tags         Authentication
	// @Accept       json
	// @Produce      json
	// @Param        resetPasswordInput  body     auth.ResetPasswordInput  true  "Email, reset code, and new password"
	// @Success      200                 {object} object{message=string}                      "Password reset successful"
	// @Failure      400                 {object} object{error=string}                        "Invalid input, code, expired code, or weak password"
	// @Failure      404                 {object} object{error=string}                        "User not found"
	// @Failure      429                 {object} object{error=string}                        "Too many requests, rate limited"
	// @Failure      500                 {object} object{error=string}                        "Internal server error"
	// @Router       /reset-password [post]
	r.POST("/reset-password", func(c *gin.Context) {
		var req auth.ResetPasswordInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		if err := svc.ResetPassword(req); err != nil {
			var userNotFoundErr *auth.UserNotFoundError
			var invalidCodeErr *auth.InvalidCodeError
			var codeExpiredErr *auth.CodeExpiredError
			var invalidPasswordErr *auth.InvalidPasswordError
			var invalidParamErr *auth.InvalidParameterError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &userNotFoundErr):
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			case errors.As(err, &invalidCodeErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid verification code"})
			case errors.As(err, &codeExpiredErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Verification code has expired"})
			case errors.As(err, &invalidPasswordErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Password does not meet requirements"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected reset password error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Password reset successful."})
	})
	// Login godoc
	// @Summary      Authenticate user
	// @Description  Authenticates user with email and password, returns JWT token for API access
	// @Tags         Authentication
	// @Accept       json
	// @Produce      json
	// @Param        loginInput  body     auth.LoginInput  true  "User email and password"
	// @Success      200         {object} object{id_token=string}                 "Login successful with JWT token"
	// @Failure      400         {object} object{error=string}                    "Invalid input provided"
	// @Failure      401         {object} object{error=string}                    "Invalid credentials"
	// @Failure      403         {object} object{error=string}                    "Account not verified"
	// @Failure      429         {object} object{error=string}                    "Too many requests, rate limited"
	// @Failure      500         {object} object{error=string}                    "Internal server error"
	// @Router       /login [post]
	r.POST("/login", func(c *gin.Context) {
		var req auth.LoginInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		idToken, err := svc.Login(req)
		if err != nil {
			var invalidCredentialsError *auth.InvalidCredentialsError
			var userNotConfirmedErr *auth.UserNotConfirmedError
			var userNotFoundErr *auth.UserNotFoundError
			var invalidParamErr *auth.InvalidParameterError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &invalidCredentialsError):
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
			case errors.As(err, &userNotConfirmedErr):
				c.JSON(http.StatusForbidden, gin.H{"error": "Account not verified. Please check your email for verification code"})
			case errors.As(err, &userNotFoundErr):
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid email or password"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected login error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{"id_token": idToken})
	})

	// GoogleLoginURL godoc
	// @Summary      Get Google OAuth login URL
	// @Description  Returns the Google OAuth login URL for Cognito-hosted authentication flow
	// @Tags         Authentication
	// @Produce      json
	// @Success      200  {object} object{url=string}      "Google OAuth login URL"
	// @Failure      500  {object} object{error=string}    "Google login not configured"
	// @Router       /login/google/url [get]
	r.GET("/login/google/url", GoogleLoginURLHandler(svc))

	// GoogleCallbackHandler godoc
	// @Summary      Handle Google OAuth callback
	// @Description  Processes the callback from Google OAuth flow, exchanges authorization code for JWT token, and creates user account if needed
	// @Tags         Authentication
	// @Produce      json
	// @Param        code  query    string  true  "OAuth authorization code from Google"
	// @Success      200   {object} object{id_token=string}   "Authentication successful with JWT token"
	// @Failure      400   {object} object{error=string}      "Missing or invalid authorization code"
	// @Failure      401   {object} object{error=string}      "Authentication failed"
	// @Failure      500   {object} object{error=string}      "Internal server error"
	// @Router       /login/google/callback [get]
	r.GET("/login/google/callback", GoogleCallbackHandler(svc, repo))

	// Resend Code godoc
	// @Summary      Resend verification code
	// @Description  Resends the account verification code to the user's email address
	// @Tags         Authentication
	// @Accept       json
	// @Produce      json
	// @Param        resendCodeInput  body     auth.ResendCodeInput  true  "User email address"
	// @Success      200              {object} object{message=string}              "Verification code resent successfully"
	// @Failure      400              {object} object{error=string}                "Invalid input provided"
	// @Failure      404              {object} object{error=string}                "User not found"
	// @Failure      429              {object} object{error=string}                "Too many requests, rate limited"
	// @Failure      500              {object} object{error=string}                "Internal server error"
	// @Router       /resend-code [post]
	r.POST("/resend-code", func(c *gin.Context) {
		var req auth.ResendCodeInput
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
			return
		}

		if err := svc.ResendConfirmationCode(req); err != nil {
			var userNotFoundErr *auth.UserNotFoundError
			var invalidParamErr *auth.InvalidParameterError
			var tooManyRequestsErr *auth.TooManyRequestsError

			switch {
			case errors.As(err, &userNotFoundErr):
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input provided"})
			case errors.As(err, &tooManyRequestsErr):
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many requests. Please try again later"})
			default:
				log.Printf("Unexpected resend code error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			}
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Verification code resent. Please check your email."})
	})
}

// GoogleLoginURLHandler returns the Cognito-hosted Google login URL
func GoogleLoginURLHandler(svc *auth.CognitoService) gin.HandlerFunc {
	return func(c *gin.Context) {
		url := svc.GetGoogleLoginURL()
		if url == "" {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Google login URL not configured"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"url": url})
	}
}

// GoogleCallbackHandler handles Cognito redirect after Google login
func GoogleCallbackHandler(svc *auth.CognitoService, repo *repositories.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		code := c.Query("code")
		if code == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing code in callback"})
			return
		}
		idToken, err := svc.ExchangeGoogleCodeForToken(code)
		if err != nil {
			var invalidParamErr *auth.InvalidParameterError
			var invalidCredentialsErr *auth.InvalidCredentialsError

			switch {
			case errors.As(err, &invalidParamErr):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid authentication code"})
			case errors.As(err, &invalidCredentialsErr):
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication failed"})
			default:
				log.Printf("Unexpected Google OAuth error: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to complete Google authentication"})
			}
			return
		}

		claims, err := svc.ParseToken(idToken)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse token"})
			return
		}

		_, err = repo.GetUserByEmail(claims.Email)
		if err != nil {
			if db.IsNotFoundError(err) {
				if err := repo.CreateUserOnSignup(claims.Subject, claims.Email, model.PlayerRole); err != nil {
					log.Printf("Failed to create user record in database: %v", err)
					httpErr := db.ToHTTPError(err)
					c.JSON(httpErr.StatusCode, httpErr)
					return
				}
			} else {
				httpErr := db.ToHTTPError(err)
				c.JSON(httpErr.StatusCode, httpErr)
				return
			}
		}

		c.JSON(http.StatusOK, gin.H{"id_token": idToken})
	}
}
