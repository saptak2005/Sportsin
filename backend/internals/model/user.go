package model

type User struct {
	AppModel
	Username       string `json:"username"`
	Email          string `json:"email"`
	Role           Role   `json:"role"`
	SnsEndpointArn string `json:"sns_endpoint_arn"`
	DeviceToken    string `json:"device_token"`
}
