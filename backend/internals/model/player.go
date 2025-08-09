package model

type Player struct {
	UserDetails
	Level           Level   `json:"level"`
	InterestLevel   Level   `json:"interest_level"`
	InterestCountry *string `json:"interest_location,omitempty"`
}
