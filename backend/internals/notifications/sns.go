package notifications

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/sns"
)

type SNSService struct {
	client            *sns.Client
	platformAppARNMap map[string]string
}

// Only keep the Android-specific constructor
func NewSNSService(region string, androidARN string) *SNSService {
	client := sns.New(sns.Options{
		Region: region,
	})
	return &SNSService{
		client: client,
		platformAppARNMap: map[string]string{
			"android": androidARN,
		},
	}
}

func (s *SNSService) RegisterDevice(token, platform string) (string, error) {
	input := &sns.CreatePlatformEndpointInput{
		PlatformApplicationArn: aws.String(s.platformAppARNMap[platform]),
		Token:                  aws.String(token),
	}
	resp, err := s.client.CreatePlatformEndpoint(context.TODO(), input)
	if err != nil {
		log.Fatal("Error initialising client")
		return "", err
	}
	return *resp.EndpointArn, nil
}

func (s *SNSService) Send(notification Notification) error {
	message := buildPlatformMessage(notification)
	input := &sns.PublishInput{
		TargetArn:        aws.String(notification.TargetARN),
		MessageStructure: aws.String("json"),
		Message:          aws.String(message),
	}

	_, err := s.client.Publish(context.TODO(), input)
	return err
}

func (s *SNSService) SendToTopic(notification Notification, topicARN string) error {
	message := buildPlatformMessage(notification)
	input := &sns.PublishInput{
		TopicArn:         aws.String(topicARN),
		MessageStructure: aws.String("json"),
		Message:          aws.String(message),
	}
	_, err := s.client.Publish(context.TODO(), input)
	return err
}

func buildPlatformMessage(n Notification) string {
	payload := map[string]any{
		"default": n.Body,
		"GCM": toJSONString(map[string]any{
			"notification": map[string]string{
				"title": n.Title,
				"body":  n.Body,
			},
			"data": n.Data,
		}),
		"APNS": toJSONString(map[string]any{
			"aps": map[string]any{
				"alert": map[string]string{
					"title": n.Title,
					"body":  n.Body,
				},
				"sound": "default",
			},
		}),
	}

	jsonBytes, _ := json.Marshal(payload)
	return string(jsonBytes)
}

func toJSONString(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}
