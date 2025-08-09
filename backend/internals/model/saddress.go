package model

type SAddress struct {
	AppModel
	Country    string `json:"country"`
	State      string `json:"state"`
	City       string `json:"city"`
	Street     string `json:"street"`
	Building   string `json:"building"`
	PostalCode string `json:"postal_code"`
}
