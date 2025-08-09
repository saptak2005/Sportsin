package model

type UserSkill struct {
	AppModel
	UserId  string `json:"user_id"`
	SportId string `json:"sport_id"`
}
