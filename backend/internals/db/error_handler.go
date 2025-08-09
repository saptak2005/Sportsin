package db

import (
	"errors"
	"log"
	"net/http"
)

// ErrorResponse represents a standardized error response
type ErrorResponse struct {
	StatusCode int    `json:"-"`
	Code       string `json:"code"`
	Message    string `json:"message"`
	Field      string `json:"field,omitempty"`
}

// ToHTTPError converts database errors to appropriate HTTP responses
func ToHTTPError(err error) ErrorResponse {
	if err == nil {
		return ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Code:       "internal_error",
			Message:    "An unexpected error occurred",
		}
	}

	// Handle our custom error types
	var notFoundErr *NotFoundError
	var alreadyExistsErr *AlreadyExistsError
	var validationErr *ValidationError
	var authErr *AuthorizationError
	var dbErr *DatabaseError

	switch {
	case errors.As(err, &notFoundErr):
		return ErrorResponse{
			StatusCode: http.StatusNotFound,
			Code:       "not_found",
			Message:    err.Error(),
		}

	case errors.As(err, &alreadyExistsErr):
		return ErrorResponse{
			StatusCode: http.StatusConflict,
			Code:       "already_exists",
			Message:    err.Error(),
			Field:      alreadyExistsErr.Field,
		}

	case errors.As(err, &validationErr):
		return ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Code:       "validation_error",
			Message:    validationErr.Message,
			Field:      validationErr.Field,
		}

	case errors.As(err, &authErr):
		return ErrorResponse{
			StatusCode: http.StatusForbidden,
			Code:       "forbidden",
			Message:    err.Error(),
		}

	case errors.As(err, &dbErr):
		// Don't expose internal database errors to users
		return ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Code:       "internal_error",
			Message:    "An internal error occurred",
		}

	default:
		log.Printf("Unhandled error: %v", err)
		return ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Code:       "internal_error",
			Message:    "An unexpected error occurred",
		}
	}
}

// IsNotFoundError checks if the error is a NotFoundError
func IsNotFoundError(err error) bool {
	var notFoundErr *NotFoundError
	return errors.As(err, &notFoundErr)
}

// IsValidationError checks if the error is a ValidationError
func IsValidationError(err error) bool {
	var validationErr *ValidationError
	return errors.As(err, &validationErr)
}

// IsAuthorizationError checks if the error is an AuthorizationError
func IsAuthorizationError(err error) bool {
	var authErr *AuthorizationError
	return errors.As(err, &authErr)
}

// IsAlreadyExistsError checks if the error is an AlreadyExistsError
func IsAlreadyExistsError(err error) bool {
	var existsErr *AlreadyExistsError
	return errors.As(err, &existsErr)
}

// IsDatabaseError checks if the error is a DatabaseError
func IsDatabaseError(err error) bool {
	var dbErr *DatabaseError
	return errors.As(err, &dbErr)
}
