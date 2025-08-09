package model

import "fmt"

type Gender string

const (
	Male         Gender = "male"
	Female       Gender = "female"
	Other        Gender = "other"
	RatherNotSay Gender = "rather_not_say"
)

type Role string

const (
	AdminRole     Role = "admin"
	PlayerRole    Role = "player"
	RecruiterRole Role = "recruiter"
)

func ParseRole(role string) (Role, error) {
	switch role {
	case "admin":
		return AdminRole, nil
	case "player":
		return PlayerRole, nil
	case "recruiter":
		return RecruiterRole, nil
	}

	return "", fmt.Errorf("invalid role: %s", role)
}

type Level string

const (
	DistrictLevel      Level = "district"
	StateLevel         Level = "state"
	CountryLevel       Level = "country"
	InternationalLevel Level = "international"
	PersonalLevel      Level = "personal"
)

type TournamentStatus string

const (
	Scheduled TournamentStatus = "scheduled"
	Started   TournamentStatus = "started"
	Ended     TournamentStatus = "ended"
	Cancelled TournamentStatus = "cancelled"
)

type ParticipationStatus string

const (
	Pending  ParticipationStatus = "pending"
	Accepted ParticipationStatus = "accepted"
	Rejected ParticipationStatus = "rejected"
)
