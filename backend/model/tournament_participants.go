package model

type TounramentParticipants struct {
	AppModel
	UserId       string              `json:"user_id"`
	TournamentId string              `json:"tournament_id"`
	Status       ParticipationStatus `json:"status"` // Status can be "pending", "accepted", "rejected"

}
