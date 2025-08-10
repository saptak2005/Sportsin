package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"sportsin_backend/internals/config"
	"sportsin_backend/internals/db"
	"sportsin_backend/internals/db/repositories"
	"sportsin_backend/internals/middleware"
	"sportsin_backend/internals/model"
)

// GetSports godoc
// @Summary Get a list of sports
// @Description Get a list of sports with optional pagination
// @Tags sports
// @Produce json
// @Param limit query int false "Limit"
// @Param offset query int false "Offset"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /sports [get]
func GetSportsHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		limitStr := ctx.DefaultQuery("limit", "10")
		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 || limit > 100 {

			ctx.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid limit",
			})
			return
		}
		offsetStr := ctx.DefaultQuery("offset", "0")
		offset, err := strconv.Atoi(offsetStr)
		if err != nil || offset < 0 {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid offset",
			})
			return
		}

		sports, err := repo.GetSports(limit, offset)
		if err != nil {
			httpError := db.ToHTTPError(err)
			ctx.JSON(httpError.StatusCode, gin.H{
				"error": httpError.Message,
			})
			return
		}

		ctx.JSON(http.StatusOK, gin.H{
			"sports": sports,
			"limit":  limit,
			"offset": offset,
		})
	}
}

type CreateSportRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

// CreateSport godoc
// @Summary Create a new sport
// @Description Create a new sport. Admin only.
// @Tags sports
// @Accept json
// @Produce json
// @Param sport body CreateSportRequest true "Sport data"
// @Success 201 {object} model.Sport
// @Failure 400 {object} map[string]string
// @Failure 401 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /sports [post]
// @Security BearerAuth
func CreateSportHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		var req CreateSportRequest
		if err := ctx.ShouldBindJSON(&req); err != nil {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid request format",
			})
			return
		}
		var sport model.Sport
		sport.Name = req.Name
		sport.Description = req.Description
		id, err := repo.CreateSport(&sport)
		if err != nil {
			httpError := db.ToHTTPError(err)
			ctx.JSON(httpError.StatusCode, gin.H{
				"error": httpError.Message,
			})
			return
		}
		sport.Id = id
		ctx.JSON(http.StatusCreated, gin.H{
			"sport": sport,
		})
	}
}

// GetSportByName godoc
// @Summary Get a sport by name
// @Description Get a single sport by its name
// @Tags sports
// @Produce json
// @Param name path string true "Sport Name"
// @Success 200 {object} model.Sport
// @Failure 400 {object} map[string]string
// @Failure 404 {object} map[string]string
// @Router /sports/{name} [get]
func GetSportByNameHandler(repo *repositories.Repository) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		name := ctx.Param("name")
		if name == "" {
			ctx.JSON(http.StatusBadRequest, gin.H{
				"error": "Sport name is required",
			})
			return
		}
		sport, err := repo.GetSportByName(name)
		if err != nil {
			httpError := db.ToHTTPError(err)
			ctx.JSON(httpError.StatusCode, gin.H{
				"error": httpError.Message,
			})
			return
		}
		ctx.JSON(http.StatusOK, gin.H{
			"sport": sport,
		})
	}

}

func RegisterSportRoutes(rg *gin.RouterGroup, cfg *config.Config, repo *repositories.Repository) {
	rg.GET("/sports", GetSportsHandler(repo))
	rg.GET("/sports/:name", GetSportByNameHandler(repo))

	protected := rg.Group("")
	protected.Use(middleware.NewJWTMiddleware(cfg).AuthMiddleware())
	rg.POST("/sports", CreateSportHandler(repo))
}
