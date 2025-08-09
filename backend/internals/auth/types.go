package auth

import (
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider"
	"github.com/golang-jwt/jwt/v5"
	"sportsin_backend/internals/model"
)

type SignupInput struct {
	Email    string     `json:"email"`
	Password string     `json:"password"`
	Phone    string     `json:"phone,omitempty"`
	Role     model.Role `json:"role"`
}

type ConfirmInput struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type LoginInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type CognitoService struct {
	client        *cognitoidentityprovider.Client
	userPoolID    string
	clientID      string
	cognitoDomain string
	redirectURI   string
}

type ForgotPasswordInput struct {
	Email string `json:"email"`
}

type ResetPasswordInput struct {
	Email       string `json:"email"`
	Code        string `json:"code"`
	NewPassword string `json:"new_password"`
}

type ResendCodeInput struct {
	Email string `json:"email"`
}

type Claims struct {
	Email   string   `json:"email"`
	Scope   string   `json:"scope"`
	Subject string   `json:"sub"`
	Role    model.Role `json:"custom:role"`
	jwt.RegisteredClaims
}