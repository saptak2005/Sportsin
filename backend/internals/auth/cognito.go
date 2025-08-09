package auth

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"net/url"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider"
	"github.com/aws/aws-sdk-go-v2/service/cognitoidentityprovider/types"
	"github.com/golang-jwt/jwt/v5"
	appConfig "sportsin_backend/internals/config"
)

func NewCognitoService(cfg *appConfig.Config) *CognitoService {
	if cfg.AWS_REGION == "" {
		log.Fatalf("❌ Missing required configuration: AWS_REGION")
	}
	if cfg.COGNITO_USER_POOL_ID == "" {
		log.Fatalf("❌ Missing required configuration: COGNITO_USER_POOL_ID")
	}
	if cfg.COGNITO_CLIENT_ID == "" {
		log.Fatalf("❌ Missing required configuration: COGNITO_CLIENT_ID")
	}

	log.Printf("✅ Loaded AWS_REGION: %s", cfg.AWS_REGION)
	log.Printf("✅ Loaded COGNITO_USER_POOL_ID: %s", cfg.COGNITO_USER_POOL_ID)
	log.Printf("✅ Loaded COGNITO_CLIENT_ID: %s", cfg.COGNITO_CLIENT_ID)

	awsCfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(cfg.AWS_REGION))
	if err != nil {
		log.Fatalf("❌ Unable to load AWS SDK config: %v", err)
	}

	log.Println("✅ AWS SDK config loaded successfully")

	return &CognitoService{
		client:        cognitoidentityprovider.NewFromConfig(awsCfg),
		userPoolID:    cfg.COGNITO_USER_POOL_ID,
		clientID:      cfg.COGNITO_CLIENT_ID,
		cognitoDomain: cfg.COGNITO_DOMAIN,
		redirectURI:   cfg.REDIRECT_URI,
	}
}

// handleCognitoError converts AWS Cognito errors to custom error types
func (s *CognitoService) handleCognitoError(err error, email string) error {
	if err == nil {
		return nil
	}

	var apiErr *types.InvalidParameterException
	var userExistsErr *types.UsernameExistsException
	var userNotFoundErr *types.UserNotFoundException
	var userNotConfirmedErr *types.UserNotConfirmedException
	var notAuthorizedErr *types.NotAuthorizedException
	var codeExpiredErr *types.ExpiredCodeException
	var invalidCodeErr *types.CodeMismatchException
	var tooManyRequestsErr *types.TooManyRequestsException
	var invalidPasswordErr *types.InvalidPasswordException

	switch {
	case errors.As(err, &userExistsErr):
		return &UserExistsError{Email: email}
	case errors.As(err, &userNotFoundErr):
		return &UserNotFoundError{Email: email}
	case errors.As(err, &userNotConfirmedErr):
		return &UserNotConfirmedError{Email: email}
	case errors.As(err, &notAuthorizedErr):
		return &InvalidCredentialsError{}
	case errors.As(err, &codeExpiredErr):
		return &CodeExpiredError{}
	case errors.As(err, &invalidCodeErr):
		return &InvalidCodeError{}
	case errors.As(err, &tooManyRequestsErr):
		return &TooManyRequestsError{}
	case errors.As(err, &invalidPasswordErr):
		return &InvalidPasswordError{Message: invalidPasswordErr.ErrorMessage()}
	case errors.As(err, &apiErr):
		return &InvalidParameterError{Parameter: "", Message: apiErr.ErrorMessage()}
	default:
		return err
	}
}
func (s *CognitoService) Signup(input SignupInput) (string, error) {
	// Validate input
	if input.Email == "" || input.Password == "" || input.Role == "" {
		return "", &InvalidParameterError{
			Parameter: "input",
			Message:   "email, password, and role are required",
		}
	}

	// Construct user attributes
	attrs := []types.AttributeType{
		{
			Name:  aws.String("email"),
			Value: aws.String(input.Email),
		},
		{
			Name:  aws.String("custom:role"), // ✅ Must use custom: prefix for custom attributes
			Value: aws.String(string(input.Role)),
		},
	}

	// Optional phone number
	if input.Phone != "" {
		attrs = append(attrs, types.AttributeType{
			Name:  aws.String("phone_number"),
			Value: aws.String(input.Phone),
		})
	}

	res, err := s.client.SignUp(context.TODO(), &cognitoidentityprovider.SignUpInput{
		ClientId:       aws.String(s.clientID),
		Username:       aws.String(input.Email),
		Password:       aws.String(input.Password),
		UserAttributes: attrs,
	})

	if err != nil {
		log.Printf("❌ SignUp error for %s: %v", input.Email, err)
		return "", s.handleCognitoError(err, input.Email)
	}

	log.Printf("✅ SignUp succeeded for %s", input.Email)
	return *res.UserSub, nil
}

func (s *CognitoService) Confirm(input ConfirmInput) error {
	if input.Email == "" || input.Code == "" {
		return &InvalidParameterError{
			Parameter: "input",
			Message:   "email and confirmation code are required",
		}
	}

	log.Printf("🔐 ConfirmSignUp for user: %s", input.Email)

	_, err := s.client.ConfirmSignUp(context.TODO(), &cognitoidentityprovider.ConfirmSignUpInput{
		ClientId:         aws.String(s.clientID),
		Username:         aws.String(input.Email),
		ConfirmationCode: aws.String(input.Code),
	})
	if err != nil {
		log.Printf("❌ ConfirmSignUp error for %s: %v", input.Email, err)
		return s.handleCognitoError(err, input.Email)
	}

	log.Printf("✅ ConfirmSignUp succeeded for %s", input.Email)
	return nil
}

func (s *CognitoService) Login(input LoginInput) (string, error) {
	if input.Email == "" || input.Password == "" {
		return "", &InvalidParameterError{
			Parameter: "input",
			Message:   "email and password are required",
		}
	}

	log.Printf("🔓 Login attempt for user: %s", input.Email)

	resp, err := s.client.InitiateAuth(context.TODO(), &cognitoidentityprovider.InitiateAuthInput{
		AuthFlow: types.AuthFlowTypeUserPasswordAuth,
		ClientId: aws.String(s.clientID),
		AuthParameters: map[string]string{
			"USERNAME": input.Email,
			"PASSWORD": input.Password,
		},
	})
	if err != nil {
		log.Printf("❌ Login error for %s: %v", input.Email, err)
		return "", s.handleCognitoError(err, input.Email)
	}

	log.Printf("✅ Login successful for %s", input.Email)
	return *resp.AuthenticationResult.IdToken, nil
}

func (s *CognitoService) ForgotPassword(input ForgotPasswordInput) error {
	if input.Email == "" {
		return &InvalidParameterError{
			Parameter: "email",
			Message:   "email is required",
		}
	}

	log.Printf("🔐 ForgotPassword request for user: %s", input.Email)

	_, err := s.client.ForgotPassword(context.TODO(), &cognitoidentityprovider.ForgotPasswordInput{
		ClientId: aws.String(s.clientID),
		Username: aws.String(input.Email),
	})
	if err != nil {
		log.Printf("❌ ForgotPassword error for %s: %v", input.Email, err)
		return s.handleCognitoError(err, input.Email)
	}

	log.Printf("✅ ForgotPassword code sent to %s", input.Email)
	return nil
}

func (s *CognitoService) ResetPassword(input ResetPasswordInput) error {
	if input.Email == "" || input.Code == "" || input.NewPassword == "" {
		return &InvalidParameterError{
			Parameter: "input",
			Message:   "email, confirmation code, and new password are required",
		}
	}

	log.Printf("🔐 ResetPassword attempt for user: %s", input.Email)

	_, err := s.client.ConfirmForgotPassword(context.TODO(), &cognitoidentityprovider.ConfirmForgotPasswordInput{
		ClientId:         aws.String(s.clientID),
		Username:         aws.String(input.Email),
		ConfirmationCode: aws.String(input.Code),
		Password:         aws.String(input.NewPassword),
	})
	if err != nil {
		log.Printf("❌ ResetPassword error for %s: %v", input.Email, err)
		return s.handleCognitoError(err, input.Email)
	}

	log.Printf("✅ Password reset successful for %s", input.Email)
	return nil
}

// GetGoogleLoginURL returns the Cognito-hosted Google login URL
func (s *CognitoService) GetGoogleLoginURL() string {
	if s.cognitoDomain == "" || s.clientID == "" || s.redirectURI == "" {
		log.Println("⚠️ Missing COGNITO_DOMAIN, CLIENT_ID, or REDIRECT_URI for Google login URL")
		return ""
	}
	return s.cognitoDomain + "/oauth2/authorize?response_type=code&client_id=" + s.clientID + "&redirect_uri=" + s.redirectURI + "&identity_provider=Google&scope=openid+email+profile"
}

// ExchangeGoogleCodeForToken exchanges the code for an ID token using Cognito's /oauth2/token endpoint
func (s *CognitoService) ExchangeGoogleCodeForToken(code string) (string, error) {
	if code == "" {
		return "", &InvalidParameterError{
			Parameter: "code",
			Message:   "authorization code is required",
		}
	}

	if s.cognitoDomain == "" || s.clientID == "" || s.redirectURI == "" {
		return "", &InvalidParameterError{
			Parameter: "config",
			Message:   "missing Cognito domain, client ID, or redirect URI configuration",
		}
	}

	form := url.Values{}
	form.Add("grant_type", "authorization_code")
	form.Add("client_id", s.clientID)
	form.Add("code", code)
	form.Add("redirect_uri", s.redirectURI)

	tokenURL := s.cognitoDomain + "/oauth2/token"
	resp, err := http.PostForm(tokenURL, form)
	if err != nil {
		log.Printf("❌ Failed to make token exchange request: %v", err)
		return "", errors.New("failed to communicate with authentication service")
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		log.Printf("❌ Token exchange failed with status %d", resp.StatusCode)
		switch resp.StatusCode {
		case 400:
			return "", &InvalidParameterError{
				Parameter: "authorization_code",
				Message:   "invalid or expired authorization code",
			}
		case 401:
			return "", &InvalidCredentialsError{}
		default:
			return "", errors.New("authentication service error")
		}
	}

	var result struct {
		IDToken          string `json:"id_token"`
		Error            string `json:"error"`
		ErrorDescription string `json:"error_description"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("❌ Failed to decode token response: %v", err)
		return "", errors.New("invalid response from authentication service")
	}

	if result.Error != "" {
		log.Printf("❌ OAuth error: %s - %s", result.Error, result.ErrorDescription)
		return "", &InvalidParameterError{
			Parameter: "oauth",
			Message:   result.ErrorDescription,
		}
	}

	if result.IDToken == "" {
		log.Printf("❌ No id_token in response")
		return "", errors.New("authentication service did not return a valid token")
	}

	log.Printf("✅ Google OAuth token exchange successful")
	return result.IDToken, nil
}

func (s *CognitoService) ResendConfirmationCode(input ResendCodeInput) error {
	if input.Email == "" {
		return &InvalidParameterError{
			Parameter: "email",
			Message:   "email is required",
		}
	}

	_, err := s.client.ResendConfirmationCode(context.TODO(), &cognitoidentityprovider.ResendConfirmationCodeInput{
		ClientId: aws.String(s.clientID),
		Username: aws.String(input.Email),
	})
	if err != nil {
		log.Printf("❌ ResendConfirmationCode error for %s: %v", input.Email, err)
		return s.handleCognitoError(err, input.Email)
	}
	log.Printf("✅ ResendConfirmationCode sent to %s", input.Email)
	return nil
}

func (s *CognitoService) ParseToken(tokenString string) (*Claims, error) {
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, &Claims{})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok {
		return claims, nil
	} else {
		return nil, errors.New("invalid token claims")
	}
}
