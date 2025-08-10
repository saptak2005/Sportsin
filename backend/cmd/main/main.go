package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	redisv9 "github.com/redis/go-redis/v9"
	_ "sportsin_backend/docs" // swag docs
	"sportsin_backend/internals/chat/redis"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/handlers"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/notifications"
	"sportsin_backend/internals/services"
)

// @title           SportsIN Backend API
// @version         1.0
// @description     A comprehensive sports networking platform API that connects players, recruiters, and sports enthusiasts.
// @description     This API provides authentication, user profile management, content sharing, and networking features.
// @termsOfService  http://swagger.io/terms/
// @contact.name   SportsIN Support
// @contact.url    http://www.sportsin.example.com/support
// @contact.email  support@sportsin.example.com
// @license.name  Apache 2.0
// @license.url   http://www.apache.org/licenses/LICENSE-2.0.html
// @host      localhost:8080
// @BasePath  /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println(" Warning: .env file not found, using environment variables")
	}
	cfg := config.LoadConfig()
	conn, err := db.Connect(cfg)
	if err != nil {
		log.Fatal("Error connecting to database")
	}
	defer conn.Close()
	err = db.RunMigrations(conn)
	if err != nil {
		log.Fatal("Error running migrations:", err)
	}
	s3Service, err := services.NewS3Service(cfg.S3_BUCKET_NAME, cfg.AWS_REGION)
	if err != nil {
		log.Fatal("Error initializing S3 service: ", err)
	}
	// Initialize repository
	repo := &repositories.Repository{DB: conn}
	// Initialize Redis client
	redisClient := redisv9.NewClient(&redisv9.Options{
		Addr: cfg.REDIS_URL,
	})
	log.Println("Connecting to Redis at", cfg.REDIS_URL)
	chatHub := redis.NewHub(redisClient)

	// CRITICAL FIX: Start the hub in a goroutine
	go chatHub.Run()

	// Initialize SNSService for notifications (Android only)
	snsService := notifications.NewSNSService(cfg.AWS_REGION, cfg.AWS_PLATFORM_ARN)
	// Register chat handlers
	chatHandler := handlers.NewChatHandler(chatHub, repo, snsService)
	r := gin.Default()
	// CORS middleware for Swagger UI
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})
	// Register documentation and health routes
	handlers.RegisterDocsRoutes(r.Group(""))
	handlers.RegisterHealthRoutes(r.Group(""))
	// Register routes
	handlers.RegisterAuthRoutes(r.Group(""), cfg, repo)
	handlers.RegisterProfileRoutes(r.Group(""), cfg, repo)
	handlers.RegisterImageRoutes(r.Group(""), cfg, repo, s3Service)
	handlers.RegisterPostRoutes(r.Group(""), cfg, repo, s3Service)
	handlers.RegisterCommentRoutes(r.Group(""), cfg, repo)
	handlers.RegisterTournamentRoutes(r.Group(""), cfg, repo, s3Service)
	handlers.RegisterAchievementRoutes(r.Group(""), cfg, repo, s3Service)
	handlers.RegisterOpeningRoutes(r.Group(""), cfg, repo)
	handlers.RegisterSportRoutes(r.Group(""), cfg, repo)
	// Register search route
	r.GET("/search/users", handlers.SearchUsersHandler(repo.DB))
	// Create JWT middleware instance
	jwtMiddleware := middleware.NewJWTMiddleware(cfg).AuthMiddleware()

	// All chat routes need authentication
	r.GET("/ws/chat", jwtMiddleware, chatHandler.ServeWs)
	r.GET("/chat/rooms", jwtMiddleware, chatHandler.GetChatRooms)
	r.GET("/chat/rooms/:roomID/messages", jwtMiddleware, chatHandler.GetMessages)
	r.POST("/chat/rooms/:roomID/read", jwtMiddleware, chatHandler.MarkRoomAsRead)
	r.Run()
}
