package model

type Recruiter struct {
	UserDetails
	OrganizationName string `json:"organization_name"`
	OrganizationId   string `json:"organization_id"`
	PhoneNumber      string `json:"phone_number"`
	Position         string `json:"position"`
}
