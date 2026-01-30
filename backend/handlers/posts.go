package handlers

import (
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

type PostResponse struct {
	ID            string   `db:"id" json:"id"`
	Owner         string   `db:"owner" json:"owner"`
	AuthorName    string   `db:"author_name" json:"author_name"`
	AuthorImage   string   `db:"author_image" json:"author_image"`
	Content       string   `db:"content" json:"content"`
	Image         string   `db:"image" json:"image"`
	LikeCount     int      `db:"like_count" json:"like_count"`
	CommentCount  int      `db:"comment_count" json:"comment_count"`
	BookmarkCount int      `db:"bookmark_count" json:"bookmark_count"`
	Created       string   `db:"created" json:"created"`
	Updated       string   `db:"updated" json:"updated"`
	IsLiked       int      `db:"is_liked" json:"-"`
	IsLikedBool   bool     `json:"is_liked"`
	Tags          []string `json:"tags"`
}

func HandleGetPosts(app core.App) func(e *core.RequestEvent) error {
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
		sort := q.Get("sort")
		if sort == "" {
			sort = "-created"
		}

		orderBy := "p.created DESC"
		if sort == "+created" || sort == "created" {
			orderBy = "p.created ASC"
		} else if sort == "-like_count" {
			orderBy = "p.like_count DESC, p.created DESC"
		} else if sort == "-comment_count" {
			orderBy = "p.comment_count DESC, p.created DESC"
		}

		var posts []PostResponse
		err := app.DB().NewQuery(`
			SELECT
				p.id, p.owner, p.author_name, p.author_image,
				p.content, p.image, p.like_count, p.comment_count,
				p.bookmark_count, p.created, p.updated,
				CASE WHEN l.id IS NOT NULL THEN 1 ELSE 0 END as is_liked
			FROM community_posts p
			LEFT JOIN likes l
				ON l.target_id = p.id
				AND l.target_type = 'post'
				AND l.user = {:userId}
			ORDER BY `+orderBy+`
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(dbx.Params{
			"userId": userId,
			"limit":  perPage,
			"offset": offset,
		}).All(&posts)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch posts", err)
		}

		var total int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM community_posts").Row(&total)

		for i := range posts {
			posts[i].IsLikedBool = posts[i].IsLiked == 1
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      posts,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

func HandleGetPost(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id
		postId := e.Request.PathValue("id")

		var post PostResponse
		err := app.DB().NewQuery(`
			SELECT
				p.id, p.owner, p.author_name, p.author_image,
				p.content, p.image, p.like_count, p.comment_count,
				p.bookmark_count, p.created, p.updated,
				CASE WHEN l.id IS NOT NULL THEN 1 ELSE 0 END as is_liked
			FROM community_posts p
			LEFT JOIN likes l
				ON l.target_id = p.id
				AND l.target_type = 'post'
				AND l.user = {:userId}
			WHERE p.id = {:postId}
		`).Bind(dbx.Params{
			"userId": userId,
			"postId": postId,
		}).One(&post)

		if err != nil {
			return apis.NewNotFoundError("Post not found", err)
		}

		post.IsLikedBool = post.IsLiked == 1

		return e.JSON(http.StatusOK, post)
	}
}
