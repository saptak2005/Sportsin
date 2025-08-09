package auth

import "fmt"

// Custom Error Types

type UserExistsError struct {
	Email string
}

func (e *UserExistsError) Error() string {
	return fmt.Sprintf("user with email '%s' already exists", e.Email)
}

type InvalidCredentialsError struct{}

func (e *InvalidCredentialsError) Error() string {
	return "invalid email or password"
}

type UserNotConfirmedError struct {
	Email string
}

func (e *UserNotConfirmedError) Error() string {
	return fmt.Sprintf("user '%s' is not confirmed. Please check your email for verification code", e.Email)
}

type UserNotFoundError struct {
	Email string
}

func (e *UserNotFoundError) Error() string {
	return fmt.Sprintf("user with email '%s' not found", e.Email)
}

type InvalidPasswordError struct {
	Message string
}

func (e *InvalidPasswordError) Error() string {
	return fmt.Sprintf("invalid password: %s", e.Message)
}

type CodeExpiredError struct{}

func (e *CodeExpiredError) Error() string {
	return "verification code has expired"
}

type InvalidCodeError struct{}

func (e *InvalidCodeError) Error() string {
	return "invalid verification code"
}

type TooManyRequestsError struct{}

func (e *TooManyRequestsError) Error() string {
	return "too many requests. Please try again later"
}

type InvalidParameterError struct {
	Parameter string
	Message   string
}

func (e *InvalidParameterError) Error() string {
	return fmt.Sprintf("invalid parameter '%s': %s", e.Parameter, e.Message)
}
