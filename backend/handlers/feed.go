package handlers

import (
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

type TrendingItem struct {
	ID           string  `db:"id" json:"id"`
	Type         string  `db:"type" json:"type"`
	Title        string  `db:"title" json:"title"`
	Content      string  `db:"content" json:"content"`
	AuthorName   string  `db:"author_name" json:"author_name"`
	LikeCount    int     `db:"like_count" json:"like_count"`
	CommentCount int     `db:"comment_count" json:"comment_count"`
	ViewCount    int     `db:"view_count" json:"view_count"`
	Score        float64 `db:"score" json:"score"`
	Created      string  `db:"created" json:"created"`
}

func HandleTrendingFeed(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 50 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		period := q.Get("period")
		var hoursAgo int
		switch period {
		case "24h":
			hoursAgo = 24
		case "30d":
			hoursAgo = 720
		default:
			hoursAgo = 168
		}

		var items []TrendingItem
		err := app.DB().NewQuery(`
			SELECT * FROM (
				SELECT
					id, 'post' as type, '' as title, content, author_name,
					like_count, comment_count, 0 as view_count,
					(like_count * 3.0 + comment_count * 2.0 + bookmark_count * 1.5)
						* (1.0 / (1.0 + (julianday('now') - julianday(created)) * 24.0 / {:hours}))
						as score,
					created
				FROM community_posts
				WHERE created >= datetime('now', '-' || {:hours} || ' hours')

				UNION ALL

				SELECT
					id, 'question' as type, title, content, '' as author_name,
					0 as like_count, comment_count, view_count,
					(comment_count * 3.0 + view_count * 0.5 + COALESCE(curious_count, 0) * 2.0)
						* (1.0 / (1.0 + (julianday('now') - julianday(created)) * 24.0 / {:hours}))
						as score,
					created
				FROM questions
				WHERE created >= datetime('now', '-' || {:hours} || ' hours')
			) combined
			ORDER BY score DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(dbx.Params{
			"hours":  hoursAgo,
			"limit":  perPage,
			"offset": offset,
		}).All(&items)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch trending feed", err)
		}

		if items == nil {
			items = []TrendingItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":   items,
			"page":    page,
			"perPage": perPage,
		})
	}
}
