package db

import (
	"fmt"
	"strings"
)

// Error types for different categories of database errors

// NotFoundError represents when a requested item doesn't exist
type NotFoundError struct {
	Resource string
	ID       string
}

func (e *NotFoundError) Error() string {
	if e.ID != "" {
		return fmt.Sprintf("%s with ID '%s' not found", e.Resource, e.ID)
	}
	return fmt.Sprintf("%s not found", e.Resource)
}

// AlreadyExistsError represents when trying to create something that already exists
type AlreadyExistsError struct {
	Resource string
	Field    string
	Value    string
}

func (e *AlreadyExistsError) Error() string {
	if e.Field != "" && e.Value != "" {
		return fmt.Sprintf("%s with %s '%s' already exists", e.Resource, e.Field, e.Value)
	}
	return fmt.Sprintf("%s already exists", e.Resource)
}

// ValidationError represents input validation failures
type ValidationError struct {
	Field   string
	Message string
}

func (e *ValidationError) Error() string {
	if e.Field != "" {
		return fmt.Sprintf("validation error for field '%s': %s", e.Field, e.Message)
	}
	return fmt.Sprintf("validation error: %s", e.Message)
}

// AuthorizationError represents permission/ownership issues
type AuthorizationError struct {
	Action   string
	Resource string
	UserID   string
}

func (e *AuthorizationError) Error() string {
	if e.Action != "" && e.Resource != "" {
		return fmt.Sprintf("user '%s' not authorized to %s %s", e.UserID, e.Action, e.Resource)
	}
	return "unauthorized access"
}

// DatabaseError represents serious database-level errors
type DatabaseError struct {
	Operation string
	Table     string
	Err       error
}

func (e *DatabaseError) Error() string {
	if e.Operation != "" && e.Table != "" {
		return fmt.Sprintf("database error during %s on %s: %v", e.Operation, e.Table, e.Err)
	}
	return fmt.Sprintf("database error: %v", e.Err)
}

func (e *DatabaseError) Unwrap() error {
	return e.Err
}

// Predefined error instances for common cases
var (
	ErrItemNotFound  = &NotFoundError{Resource: "item"}
	ErrUserNotFound  = &NotFoundError{Resource: "user"}
	ErrPostNotFound  = &NotFoundError{Resource: "post"}
	ErrImageNotFound = &NotFoundError{Resource: "image"}

	ErrUserAlreadyExists = &AlreadyExistsError{Resource: "user"}
	ErrUsernameExists    = &AlreadyExistsError{Resource: "user", Field: "username"}
	ErrEmailExists       = &AlreadyExistsError{Resource: "user", Field: "email"}
	ErrPostAlreadyExists = &AlreadyExistsError{Resource: "post"}

	ErrInvalidProfileType = &ValidationError{Field: "profile_type", Message: "invalid profile type"}
	ErrUserIDMissing      = &ValidationError{Field: "user_id", Message: "user ID is missing from the profile"}
	ErrContentEmpty       = &ValidationError{Field: "content", Message: "content cannot be empty"}
	ErrInvalidLimit       = &ValidationError{Field: "limit", Message: "limit must be greater than 0"}
	ErrInvalidOffset      = &ValidationError{Field: "offset", Message: "offset cannot be negative"}

	ErrUnauthorized = &AuthorizationError{}
	ErrRoleMismatch = &AuthorizationError{Action: "access", Resource: "resource"}
)

// Backward compatibility - deprecated constants
// TODO: Remove these once all repositories are updated to use the new error types
var (
	ITEM_NOT_FOUND          = ErrItemNotFound
	ITEM_ALREADY_EXISTS     = &AlreadyExistsError{Resource: "item"}
	USER_NOT_FOUND          = ErrUserNotFound
	USERNAME_ALREADY_EXISTS = ErrUsernameExists
	EMAIL_ALREADY_EXISTS    = ErrEmailExists
	INVALID_PROFILE_TYPE    = ErrInvalidProfileType
	USER_ID_MISSING         = ErrUserIDMissing
	ROLE_MISMATCH           = ErrRoleMismatch
)

// Helper functions to create specific error instances
func NewNotFoundError(resource, id string) *NotFoundError {
	return &NotFoundError{Resource: resource, ID: id}
}

func NewAlreadyExistsError(resource, field, value string) *AlreadyExistsError {
	return &AlreadyExistsError{Resource: resource, Field: field, Value: value}
}

func NewValidationError(field, message string) *ValidationError {
	return &ValidationError{Field: field, Message: message}
}

func NewAuthorizationError(action, resource, userID string) *AuthorizationError {
	return &AuthorizationError{Action: action, Resource: resource, UserID: userID}
}

func NewDatabaseError(operation, table string, err error) *DatabaseError {
	return &DatabaseError{Operation: operation, Table: table, Err: err}
}

// IsUniqueConstraintError checks if an error is a unique constraint violation for a specific field
func IsUniqueConstraintError(err error, field string) bool {
	if err == nil {
		return false
	}
	errMsg := strings.ToLower(err.Error())
	return strings.Contains(errMsg, "unique") && strings.Contains(errMsg, strings.ToLower(field))
}
