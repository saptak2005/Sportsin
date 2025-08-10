package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/services"
)

type UserSearchResult struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Username string `json:"username"`
}

func SearchUsersHandler(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		query := c.Query("q")
		if query == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Missing search query"})
			return
		}
		results, err := services.SearchUsers(db, query)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, results)
	}
}
