package notifications

type Notification struct {
	Title     string
	Body      string
	Data      map[string]string //extra payload for bigger messages
	TargetARN string            //SNS ARN endpoint
	Platform  string            // ios or Android
	Type      string
}

type Notifier interface {
	Send(notification Notification)
}
