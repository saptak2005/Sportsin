package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// RegisterDocsRoutes registers all documentation-related routes
func RegisterDocsRoutes(rg *gin.RouterGroup) {
	// API Documentation routes
	docs := rg.Group("/docs")
	{
		// Swagger UI with custom configuration
		// @Summary      Swagger UI
		// @Description  Interactive API documentation using Swagger UI
		// @Tags         Documentation
		// @Produce      html
		// @Router       /docs/swagger/ [get]
		docs.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler,
			ginSwagger.URL("/docs/swagger/doc.json"),
			ginSwagger.DocExpansion("list"),
			ginSwagger.DeepLinking(true),
			ginSwagger.DefaultModelsExpandDepth(1),
		))

		// API documentation landing page
		// @Summary      API Documentation Home
		// @Description  Landing page with links to all documentation resources and available endpoints
		// @Tags         Documentation
		// @Produce      json
		// @Success      200  {object}  object{message=string,version=string,swagger_ui=string,openapi_spec=string,endpoints=object}
		// @Router       /docs [get]
		docs.GET("/", ApiDocumentationHandler)
	}

	// Legacy swagger route for backward compatibility
	// @Summary      Legacy Swagger Redirect
	// @Description  Redirects to the new Swagger UI location for backward compatibility
	// @Tags         Documentation
	// @Produce      html
	// @Success      301
	// @Router       /swagger/ [get]
	rg.GET("/swagger/*any", LegacySwaggerRedirectHandler)
}

// ApiDocumentationHandler provides API documentation landing page
func ApiDocumentationHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message":            "SportsIN Backend API Documentation",
		"version":            "1.0.0",
		"description":        "A comprehensive sports networking platform API",
		"swagger_ui":         "/docs/swagger/index.html",
		"openapi_spec":       "/docs/swagger/swagger.json",
		"postman_collection": "/docs/swagger/swagger.json",
		"endpoints": gin.H{
			"health": "/health - Server health check",
			"authentication": map[string]string{
				"signup":           "/signup - Register new user",
				"login":            "/login - User authentication",
				"verify":           "/verify - Email verification",
				"forgot_password":  "/forgot-password - Password reset request",
				"reset_password":   "/reset-password - Complete password reset",
				"resend_code":      "/resend-code - Resend verification code",
				"google_login_url": "/login/google/url - Get Google OAuth URL",
				"google_callback":  "/login/google/callback - Google OAuth callback",
			},
			"profiles": map[string]string{
				"create_profile": "/profile - Create user profile (POST)",
				"update_profile": "/profile - Update user profile (PUT)",
				"get_my_profile": "/profile/me - Get current user's profile",
				"get_profile":    "/profile/{id} - Get user profile by ID",
			},
			"images": map[string]string{
				"upload_image": "/image/upload - Upload image",
				"get_image":    "/image/{id} - Get image by ID",
			},
			"posts": map[string]string{
				"create_post": "/post - Create new post (POST)",
				"get_posts":   "/post - Get all posts (GET)",
				"get_post":    "/post/{id} - Get post by ID",
				"update_post": "/post/{id} - Update post",
				"delete_post": "/post/{id} - Delete post",
			},
		},
		"authentication_info": gin.H{
			"type":         "Bearer Token",
			"description":  "Use 'Bearer <your-jwt-token>' in Authorization header",
			"obtain_token": "Login via /login or /login/google/callback endpoints",
		},
		"support": gin.H{
			"contact": "support@sportsin.example.com",
			"github":  "https://github.com/sportsin/backend",
		},
	})
}

// LegacySwaggerRedirectHandler redirects legacy swagger routes
func LegacySwaggerRedirectHandler(c *gin.Context) {
	c.Redirect(http.StatusMovedPermanently, "/docs/swagger/index.html")
}

// RegisterHealthRoutes registers health check routes
func RegisterHealthRoutes(rg *gin.RouterGroup) {
	// Health check endpoint with API information
	// @Summary      Health Check
	// @Description  Returns server health status and API information. Supports both GET and HEAD methods for monitoring.
	// @Tags         System
	// @Produce      json
	// @Success      200  {object}  object{status=string,message=string,version=string,documentation=string,swagger_ui=string}
	// @Router       /health [get]
	// @Router       /health [head]
	rg.GET("/health", HealthCheckHandler)
	rg.HEAD("/health", HealthCheckHandler)
}

// HealthCheckHandler provides server health status
func HealthCheckHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":        "healthy",
		"message":       "SportsIN Backend is running",
		"version":       "1.0.0",
		"uptime":        "Server is operational",
		"documentation": "/docs",
		"swagger_ui":    "/docs/swagger/index.html",
		"api_version":   "v1",
		"environment":   gin.Mode(),
	})
}
