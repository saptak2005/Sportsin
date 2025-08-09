package model

type Opening struct {
	AppModel
	SportID            string        `json:"sport_id"`
	RecruiterID        string        `json:"recruiter_id"`
	CompanyName        string        `json:"company_name"`
	Status             OpeningStatus `json:"status"`
	Title              string        `json:"title"`
	Description        string        `json:"description"`
	Position           string        `json:"position"`
	MinAge             *int          `json:"min_age,omitempty"`
	MaxAge             *int          `json:"max_age,omitempty"`
	MinLevel           *string       `json:"min_level,omitempty"`
	MinSalary          *int          `json:"min_salary,omitempty"`
	MaxSalary          *int          `json:"max_salary,omitempty"`
	CountryRestriction *string       `json:"country_restriction,omitempty"`
	AddressID          string        `json:"address_id,omitempty"`
	Stats              any           `json:"stats,omitempty"`
}

type OpeningStatus string

const (
	OpeningStatusOpen   OpeningStatus = "open"
	OpeningStatusClosed OpeningStatus = "closed"
)
