package handlers

import (
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

type QuestionResponse struct {
	ID           string `db:"id" json:"id"`
	Owner        string `db:"owner" json:"owner"`
	Title        string `db:"title" json:"title"`
	Content      string `db:"content" json:"content"`
	Category     string `db:"category" json:"category"`
	ViewCount    int    `db:"view_count" json:"view_count"`
	CommentCount int    `db:"comment_count" json:"comment_count"`
	CuriousCount int    `db:"curious_count" json:"curious_count"`
	Created      string `db:"created" json:"created"`
	Updated      string `db:"updated" json:"updated"`
	IsCurious    int    `db:"is_curious" json:"-"`
	IsCuriousBool bool  `json:"is_curious"`
}

func HandleGetQuestions(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		category := q.Get("category")
		sort := q.Get("sort")
		if sort == "" {
			sort = "-created"
		}

		orderBy := "q.created DESC"
		if sort == "+created" || sort == "created" {
			orderBy = "q.created ASC"
		} else if sort == "-view_count" {
			orderBy = "q.view_count DESC, q.created DESC"
		} else if sort == "-comment_count" {
			orderBy = "q.comment_count DESC, q.created DESC"
		}

		filterSQL := ""
		params := dbx.Params{
			"userId": userId,
			"limit":  perPage,
			"offset": offset,
		}
		if category != "" {
			filterSQL = "WHERE q.category = {:category}"
			params["category"] = category
		}

		var questions []QuestionResponse
		err := app.DB().NewQuery(`
			SELECT
				q.id, q.owner, q.title, q.content, q.category,
				q.view_count, q.comment_count,
				COALESCE(q.curious_count, 0) as curious_count,
				q.created, q.updated,
				CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END as is_curious
			FROM questions q
			LEFT JOIN curious c
				ON c.question_id = q.id
				AND c.user_id = {:userId}
			` + filterSQL + `
			ORDER BY ` + orderBy + `
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&questions)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch questions", err)
		}

		countQuery := "SELECT COUNT(*) FROM questions"
		countParams := dbx.Params{}
		if category != "" {
			countQuery += " WHERE category = {:category}"
			countParams["category"] = category
		}
		var total int
		_ = app.DB().NewQuery(countQuery).Bind(countParams).Row(&total)

		for i := range questions {
			questions[i].IsCuriousBool = questions[i].IsCurious == 1
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      questions,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

func HandleGetQuestion(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id
		questionId := e.Request.PathValue("id")

		var question QuestionResponse
		err := app.DB().NewQuery(`
			SELECT
				q.id, q.owner, q.title, q.content, q.category,
				q.view_count, q.comment_count,
				COALESCE(q.curious_count, 0) as curious_count,
				q.created, q.updated,
				CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END as is_curious
			FROM questions q
			LEFT JOIN curious c
				ON c.question_id = q.id
				AND c.user_id = {:userId}
			WHERE q.id = {:questionId}
		`).Bind(dbx.Params{
			"userId":     userId,
			"questionId": questionId,
		}).One(&question)

		if err != nil {
			return apis.NewNotFoundError("Question not found", err)
		}

		question.IsCuriousBool = question.IsCurious == 1

		return e.JSON(http.StatusOK, question)
	}
}
