package model

type Tournament struct {
	AppModel
	HostId      string            `json:"host_id"`
	Title       string            `json:"title"`
	Description *string           `json:"description,omitempty"`
	Location    string            `json:"location"`
	SportId     string            `json:"sport_id"`
	MinAge      *int              `json:"min_age,omitempty"`
	MaxAge      *int              `json:"max_age,omitempty"`
	Level       *Level            `json:"level,omitempty"`
	Gender      *Gender           `json:"gender,omitempty"`
	Country     *string           `json:"country,omitempty"`
	Status      *TournamentStatus `json:"status,omitempty"`
	StartDate   string            `json:"start_date"`
	EndDate     string            `json:"end_date"`
	BannerUrl   *string           `json:"banner_url,omitempty"`
}

type TournamentDetails struct {
	Tournament        *Tournament `json:"tournament"`
	HostName          string      `json:"host_name"`
	Sport             *Sport      `json:"sport"`
	IsEnrolled        bool        `json:"is_enrolled"`
	ParticipantsCount int         `json:"participants_count"`
}
