package model

type Achievement struct {
	AppModel
	UserId         string  `json:"user_id"`
	Date           string  `json:"date"`
	SportId        string  `json:"sport_id"`
	Tournament     string  `json:"tournament"`
	Description    string  `json:"description"`
	Level          Level   `json:"level"`
	Stats          any     `json:"stats"`
	CertificateUrl *string `json:"certificate_url,omitempty"`
}
