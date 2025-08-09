package model

type Address struct {
	AppModel
	UserId     string `json:"user_id"`
	Country    string `json:"country"`
	State      string `json:"state"`
	City       string `json:"city"`
	Street     string `json:"street"`
	Building   string `json:"building"`
	PostalCode string `json:"postal_code"`
}
