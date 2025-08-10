package middleware

import (
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"sportsin_backend/internals/config"
)

type JWKSet struct {
	Keys []JWK `json:"keys"`
}

type JWK struct {
	Kty string `json:"kty"`
	Kid string `json:"kid"`
	Use string `json:"use"`
	N   string `json:"n"`
	E   string `json:"e"`
	Alg string `json:"alg"`
}

type JWTMiddleware struct {
	config   *config.Config
	jwkCache map[string]*rsa.PublicKey
}

func NewJWTMiddleware(cfg *config.Config) *JWTMiddleware {
	return &JWTMiddleware{
		config:   cfg,
		jwkCache: make(map[string]*rsa.PublicKey),
	}
}

func (m *JWTMiddleware) fetchJWKS() (*JWKSet, error) {
	jwksURL := fmt.Sprintf("https://cognito-idp.%s.amazonaws.com/%s/.well-known/jwks.json",
		m.config.AWS_REGION, m.config.COGNITO_USER_POOL_ID)

	resp, err := http.Get(jwksURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch JWKS: %s", resp.Status)
	}

	var jwks JWKSet
	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, err
	}

	return &jwks, nil
}

func (m *JWTMiddleware) getPublicKey(kid string) (*rsa.PublicKey, error) {
	log.Printf("[AUTH] Token header kid: %s", kid)
	if key, exists := m.jwkCache[kid]; exists {
		log.Printf("[AUTH] Found kid in cache: %s", kid)
		return key, nil
	}

	jwks, err := m.fetchJWKS()
	if err != nil {
		return nil, err
	}

	var availableKids []string
	for _, jwk := range jwks.Keys {
		availableKids = append(availableKids, jwk.Kid)
		if jwk.Kid == kid {
			key, err := m.jwkToRSAPublicKey(jwk)
			if err != nil {
				return nil, err
			}

			m.jwkCache[kid] = key
			log.Printf("[AUTH] Found kid in JWKs: %s", kid)
			return key, nil
		}
	}
	log.Printf("[AUTH] Available kids from JWKs: %v", availableKids)
	log.Printf("[AUTH] kid not found in JWKs: %s", kid)
	return nil, errors.New("key not found")
}

func (m *JWTMiddleware) jwkToRSAPublicKey(jwk JWK) (*rsa.PublicKey, error) {
	nBytes, err := base64.RawURLEncoding.DecodeString(jwk.N)
	if err != nil {
		return nil, err
	}

	eBytes, err := base64.RawURLEncoding.DecodeString(jwk.E)
	if err != nil {
		return nil, err
	}

	n := new(big.Int).SetBytes(nBytes)
	e := new(big.Int).SetBytes(eBytes)

	publicKey := &rsa.PublicKey{
		N: n,
		E: int(e.Int64()),
	}

	return publicKey, nil
}

func logRawJWTHeader(tokenString string) {
	parts := strings.Split(tokenString, ".")
	if len(parts) < 2 {
		log.Println("[AUTH] Invalid JWT format")
		return
	}
	headerSegment := parts[0]
	headerBytes, err := base64.RawURLEncoding.DecodeString(headerSegment)
	if err != nil {
		log.Printf("[AUTH] Error decoding JWT header: %v", err)
		return
	}
	var headerMap map[string]interface{}
	if err := json.Unmarshal(headerBytes, &headerMap); err != nil {
		log.Printf("[AUTH] Error unmarshalling JWT header: %v", err)
		return
	}
	log.Printf("[AUTH] Raw JWT header: %v", headerMap)
}

func (m *JWTMiddleware) validateToken(tokenString string) (jwt.MapClaims, error) {
	logRawJWTHeader(tokenString)

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}

		kid, ok := token.Header["kid"].(string)
		if !ok {
			return nil, errors.New("kid not found in token header")
		}

		return m.getPublicKey(kid)
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("token is not valid")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	now := time.Now().Unix()

	if exp, ok := claims["exp"].(float64); ok {
		if int64(exp) < now {
			return nil, errors.New("token has expired")
		}
	}

	if nbf, ok := claims["nbf"].(float64); ok {
		if int64(nbf) > now {
			return nil, errors.New("token not yet valid")
		}
	}

	if iat, ok := claims["iat"].(float64); ok {
		if int64(iat) > now {
			return nil, errors.New("token used before issued")
		}
	}

	if aud, ok := claims["aud"].(string); ok {
		if aud != m.config.COGNITO_CLIENT_ID {
			return nil, errors.New("invalid audience")
		}
	}

	expectedIssuer := fmt.Sprintf("https://cognito-idp.%s.amazonaws.com/%s",
		m.config.AWS_REGION, m.config.COGNITO_USER_POOL_ID)
	if iss, ok := claims["iss"].(string); ok {
		if iss != expectedIssuer {
			return nil, errors.New("invalid issuer")
		}
	}

	if tokenUse, ok := claims["token_use"].(string); ok {
		if tokenUse != "id" {
			return nil, errors.New("invalid token use")
		}
	}

	return claims, nil
}

func (m *JWTMiddleware) AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			log.Println("[AUTH] Missing Authorization header")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer ") {
			log.Println("[AUTH] Authorization header does not start with 'Bearer '")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header must start with 'Bearer '"})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		log.Printf("[AUTH] Token string: %s", tokenString)
		if tokenString == "" {
			log.Println("[AUTH] Bearer token is required but missing")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Bearer token is required"})
			c.Abort()
			return
		}

		claims, err := m.validateToken(tokenString)
		if err != nil {
			log.Printf("[AUTH] Token validation failed: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		email, ok := claims["email"].(string)
		if !ok {
			log.Println("[AUTH] Email not found in token claims")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Email not found in token"})
			c.Abort()
			return
		}

		userID, ok := claims["sub"].(string)
		if !ok {
			log.Println("[AUTH] User ID not found in token claims")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in token"})
			c.Abort()
			return
		}

		var role string
		if roleAttr, ok := claims["custom:role"].(string); ok {
			role = roleAttr
		} else {
			log.Println("[AUTH] Role not found in token claims")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Role not found in token"})
			c.Abort()
			return
		}

		c.Set("email", email)
		c.Set("userID", userID)
		c.Set("role", role)
		c.Set("user_claims", claims)

		c.Next()
	}
}

func GetEmailFromContext(c *gin.Context) (string, bool) {
	email, exists := c.Get("email")
	if !exists {
		return "", false
	}
	emailStr, ok := email.(string)
	return emailStr, ok
}

func GetUserIDFromContext(c *gin.Context) (string, bool) {
	userID, exists := c.Get("userID")
	if !exists {
		return "", false
	}
	userIDStr, ok := userID.(string)
	return userIDStr, ok
}

func GetRoleFromContext(c *gin.Context) (string, bool) {
	role, exists := c.Get("role")
	if !exists {
		return "", false
	}
	roleStr, ok := role.(string)
	return roleStr, ok
}

func GetUserClaimsFromContext(c *gin.Context) (jwt.MapClaims, bool) {
	claims, exists := c.Get("user_claims")
	if !exists {
		return nil, false
	}
	claimsMap, ok := claims.(jwt.MapClaims)
	return claimsMap, ok
}
