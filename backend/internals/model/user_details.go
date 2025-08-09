package model

type UserDetails struct {
	User
	UserName       string  `json:"user_name"`
	ProfilePicture *string `json:"profile_picture,omitempty"`
	Name           string  `json:"name"`
	MiddleName     *string `json:"middle_name,omitempty"`
	Surname        string  `json:"surname"`
	DOB            string  `json:"dob"`
	Gender         Gender  `json:"gender"`
	IsPremium      bool    `json:"is_premium"`
	About          *string `json:"about,omitempty"`
	ReferalCode    *string `json:"referal_code,omitempty"`
	RefferedBy     *string `json:"reffered_by,omitempty"`
	Coins          int     `json:"coins"`
}
