package model

type Sport struct {
	AppModel
	Name        string `json:"name"`
	Description string `json:"description"`
}
