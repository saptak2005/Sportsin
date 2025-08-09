package model

type Application struct {
	AppModel
	PlayerID  string            `json:"player_id"`
	OpeningID string            `json:"opening_id"`
	Status    ApplicationStatus `json:"status"`
}

type ApplicationStatus string

const (
	ApplicationStatusPending   ApplicationStatus = "pending"
	ApplicationStatusAccepted  ApplicationStatus = "accepted"
	ApplicationStatusRejected  ApplicationStatus = "rejected"
	ApplicationStatusWithdrawn ApplicationStatus = "withdrawn"
)

type Applicant struct {
	Player
	OpeningID string            `json:"opening_id"`
	Status    ApplicationStatus `json:"status"`
}
