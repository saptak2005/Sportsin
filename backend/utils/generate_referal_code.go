package utils

import "math/rand"

const (
	domains = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
)

func GenerateReferalCode() string {
	code := ""
	domainLength := len(domains)
	for range 6 {
		code += string(domains[rand.Intn(domainLength)])
	}
	return code
}
