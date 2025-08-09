package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	COGNITO_USER_POOL_ID string
	COGNITO_CLIENT_ID    string
	COGNITO_DOMAIN       string
	AWS_REGION           string
	DATABASE_URL         string
	REDIRECT_URI         string
	S3_BUCKET_NAME       string
	REDIS_URL            string // Added Redis URL
	AWS_PLATFORM_ARN     string // Added Platform ARN
	AWS_TOPIC_ARN        string // Added Topic ARN
	PORT                 string // Added Port
}

func LoadConfig() *Config {
	godotenv.Load()

	return &Config{
		COGNITO_USER_POOL_ID: os.Getenv("COGNITO_USER_POOL_ID"),
		COGNITO_CLIENT_ID:    os.Getenv("COGNITO_CLIENT_ID"),
		COGNITO_DOMAIN:       os.Getenv("COGNITO_DOMAIN"),
		AWS_REGION:           os.Getenv("AWS_REGION"),
		DATABASE_URL:         os.Getenv("DATABASE_URL"),
		REDIRECT_URI:         os.Getenv("REDIRECT_URI"),
		S3_BUCKET_NAME:       os.Getenv("S3_BUCKET_NAME"),
		REDIS_URL:            os.Getenv("REDIS_URL"),
		AWS_PLATFORM_ARN:     os.Getenv("AWS_PLATFORM_ARN"),
		AWS_TOPIC_ARN:        os.Getenv("AWS_TOPIC_ARN"),
		PORT:                 os.Getenv("PORT"),
	}
}
