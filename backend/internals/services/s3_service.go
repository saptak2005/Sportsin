package services

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Service struct {
	client     *s3.Client
	bucketName string
	region     string
}

func NewS3Service(bucketName, region string) (*S3Service, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)

	return &S3Service{
		client:     client,
		bucketName: bucketName,
		region:     region,
	}, nil
}

// UploadProfilePicture uploads a profile picture to S3 using the Cognito user ID as the key
func (s *S3Service) UploadProfilePicture(ctx context.Context, userID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	// Validate file type
	if !s.isValidImageType(header.Filename) {
		return "", fmt.Errorf("invalid file type. Only JPEG, PNG, and GIF files are allowed")
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	file.Seek(0, 0)

	fileExtension := filepath.Ext(header.Filename)
	s3Key := fmt.Sprintf("profile-pictures/%s%s", userID, fileExtension)

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(s3Key),
		Body:        bytes.NewReader(fileContent),
		ContentType: aws.String(s.getContentType(fileExtension)),
		// ACL:         types.ObjectCannedACLPublicRead,
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload file to S3: %w", err)
	}

	// Generate and return the public URL
	imageURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, s3Key)
	return imageURL, nil
}

// GetProfilePictureURL returns the S3 URL for a user's profile picture
func (s *S3Service) GetProfilePictureURL(userID string, fileExtension string) string {
	if fileExtension == "" {
		fileExtension = ".jpg" // default extension
	}
	s3Key := fmt.Sprintf("profile-pictures/%s%s", userID, fileExtension)
	return fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, s3Key)
}

// DeleteProfilePicture deletes a user's profile picture from S3
func (s *S3Service) DeleteProfilePicture(ctx context.Context, userID string, fileExtension string) error {
	s3Key := fmt.Sprintf("profile-pictures/%s%s", userID, fileExtension)

	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(s3Key),
	})

	if err != nil {
		return fmt.Errorf("failed to delete profile picture from S3: %w", err)
	}

	return nil
}

// GeneratePresignedURL generates a presigned URL for uploading profile pictures
func (s *S3Service) GeneratePresignedURL(ctx context.Context, userID string, fileExtension string, duration time.Duration) (string, error) {
	s3Key := fmt.Sprintf("profile-pictures/%s%s", userID, fileExtension)

	presignClient := s3.NewPresignClient(s.client)

	request, err := presignClient.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(s3Key),
		ContentType: aws.String(s.getContentType(fileExtension)),
		// ACL:         types.ObjectCannedACLPublicRead, // Removed for Bucket Owner Enforced
	}, func(opts *s3.PresignOptions) {
		opts.Expires = duration
	})

	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return request.URL, nil
}

// UploadPostImage uploads a post image to S3 in the posts folder
func (s *S3Service) UploadPostImage(ctx context.Context, postID, imageID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	// Validate file type
	if !s.isValidImageType(header.Filename) {
		return "", fmt.Errorf("invalid file type. Only JPEG, PNG, and GIF files are allowed")
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	file.Seek(0, 0)

	fileExtension := filepath.Ext(header.Filename)
	s3Key := fmt.Sprintf("posts/%s/%s%s", postID, imageID, fileExtension)

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(s3Key),
		Body:        bytes.NewReader(fileContent),
		ContentType: aws.String(s.getContentType(fileExtension)),
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload post image to S3: %w", err)
	}

	// Generate and return the public URL
	imageURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, s3Key)
	return imageURL, nil
}

// DeletePostImage deletes a post image from S3
func (s *S3Service) DeletePostImage(ctx context.Context, imageURL string) error {
	// Extract S3 key from URL
	s3Key, err := s.extractS3KeyFromURL(imageURL)
	if err != nil {
		return fmt.Errorf("failed to extract S3 key from URL: %w", err)
	}

	_, err = s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(s3Key),
	})

	if err != nil {
		return fmt.Errorf("failed to delete post image from S3: %w", err)
	}

	return nil
}

// DeletePostFolder deletes all images in a post folder
func (s *S3Service) DeletePostFolder(ctx context.Context, postID string) error {
	prefix := fmt.Sprintf("posts/%s/", postID)

	// List objects with the prefix
	listInput := &s3.ListObjectsV2Input{
		Bucket: aws.String(s.bucketName),
		Prefix: aws.String(prefix),
	}

	result, err := s.client.ListObjectsV2(ctx, listInput)
	if err != nil {
		return fmt.Errorf("failed to list objects for post %s: %w", postID, err)
	}

	// Delete each object
	for _, obj := range result.Contents {
		_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
			Bucket: aws.String(s.bucketName),
			Key:    obj.Key,
		})
		if err != nil {
			return fmt.Errorf("failed to delete object %s: %w", *obj.Key, err)
		}
	}

	return nil
}

// UploadTournamentBanner uploads a tournament banner to S3 in the tournaments folder
func (s *S3Service) UploadTournamentBanner(ctx context.Context, hostID, bannerID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	// Validate file type
	if !s.isValidImageType(header.Filename) {
		return "", fmt.Errorf("invalid file type. Only JPEG, PNG, and GIF files are allowed")
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	file.Seek(0, 0)

	fileExtension := filepath.Ext(header.Filename)
	s3Key := fmt.Sprintf("tournaments/%s/%s%s", hostID, bannerID, fileExtension)

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(s3Key),
		Body:        bytes.NewReader(fileContent),
		ContentType: aws.String(s.getContentType(fileExtension)),
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload tournament banner to S3: %w", err)
	}

	// Generate and return the public URL
	imageURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, s3Key)
	return imageURL, nil
}

// DeleteTournamentBanner deletes a tournament banner from S3
func (s *S3Service) DeleteTournamentBanner(ctx context.Context, imageURL string) error {
	// Extract S3 key from URL
	s3Key, err := s.extractS3KeyFromURL(imageURL)
	if err != nil {
		return fmt.Errorf("failed to extract S3 key from URL: %w", err)
	}

	_, err = s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(s3Key),
	})

	if err != nil {
		return fmt.Errorf("failed to delete tournament banner from S3: %w", err)
	}

	return nil
}

// UploadCertificate uploads an achievement certificate to S3 in the certificates folder
func (s *S3Service) UploadCertificate(ctx context.Context, userID, achievementID string, file multipart.File, header *multipart.FileHeader) (string, error) {
	// Validate file type - allow PDF and images for certificates
	if !s.isValidCertificateType(header.Filename) {
		return "", fmt.Errorf("invalid file type. Only PDF, JPEG, PNG, and GIF files are allowed for certificates")
	}

	// Read file content
	fileContent, err := io.ReadAll(file)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	file.Seek(0, 0)

	fileExtension := filepath.Ext(header.Filename)
	s3Key := fmt.Sprintf("certificates/%s/%s%s", userID, achievementID, fileExtension)

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucketName),
		Key:         aws.String(s3Key),
		Body:        bytes.NewReader(fileContent),
		ContentType: aws.String(s.getCertificateContentType(fileExtension)),
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload certificate to S3: %w", err)
	}

	// Generate and return the public URL
	imageURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, s3Key)
	return imageURL, nil
}

// DeleteCertificate deletes a certificate from S3
func (s *S3Service) DeleteCertificate(ctx context.Context, imageURL string) error {
	// Extract S3 key from URL
	s3Key, err := s.extractS3KeyFromURL(imageURL)
	if err != nil {
		return fmt.Errorf("failed to extract S3 key from URL: %w", err)
	}

	_, err = s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucketName),
		Key:    aws.String(s3Key),
	})

	if err != nil {
		return fmt.Errorf("failed to delete certificate from S3: %w", err)
	}

	return nil
}

// extractS3KeyFromURL extracts the S3 key from a full S3 URL
func (s *S3Service) extractS3KeyFromURL(imageURL string) (string, error) {
	expectedPrefix := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/", s.bucketName, s.region)
	if !strings.HasPrefix(imageURL, expectedPrefix) {
		return "", fmt.Errorf("invalid S3 URL format")
	}

	s3Key := strings.TrimPrefix(imageURL, expectedPrefix)
	if s3Key == "" {
		return "", fmt.Errorf("empty S3 key")
	}

	return s3Key, nil
}

// isValidImageType checks if the file type is a valid image type
func (s *S3Service) isValidImageType(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	validTypes := []string{".jpg", ".jpeg", ".png", ".gif"}

	for _, validType := range validTypes {
		if ext == validType {
			return true
		}
	}
	return false
}

// getContentType returns the appropriate content type for the file extension
func (s *S3Service) getContentType(extension string) string {
	switch strings.ToLower(extension) {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	default:
		return "application/octet-stream"
	}
}

// isValidCertificateType checks if the file type is valid for certificates (images + PDF)
func (s *S3Service) isValidCertificateType(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	validTypes := []string{".jpg", ".jpeg", ".png", ".gif", ".pdf"}

	for _, validType := range validTypes {
		if ext == validType {
			return true
		}
	}
	return false
}

// getCertificateContentType returns the appropriate content type for certificate files
func (s *S3Service) getCertificateContentType(extension string) string {
	switch strings.ToLower(extension) {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	case ".pdf":
		return "application/pdf"
	default:
		return "application/octet-stream"
	}
}
