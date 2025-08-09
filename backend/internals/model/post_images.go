package model

type PostImage struct {
	AppModel
	PostId   string `json:"post_id"`
	ImageUrl string `json:"image_url"`
}
