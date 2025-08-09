package model

// OpeningDetails represents a complete opening with address and sport information
type OpeningDetails struct {
	Opening           *Opening           `json:"opening"`
	SportName         string             `json:"sport_name"`
	Address           *SAddress          `json:"address"`
	Applied           bool               `json:"applied"`
	ApplicationStatus *ApplicationStatus `json:"application_status,omitempty"`
}
