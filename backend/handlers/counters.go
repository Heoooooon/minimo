package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func HandleIncrementView(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			ID   string `json:"id"`
			Type string `json:"type"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		var table string
		switch body.Type {
		case "question":
			table = "questions"
		case "post":
			table = "community_posts"
		default:
			return apis.NewBadRequestError("type must be 'question' or 'post'", nil)
		}

		_, err := app.DB().NewQuery(
			"UPDATE "+table+" SET view_count = view_count + 1 WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.ID}).Execute()
		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to increment view", err)
		}

		return e.JSON(http.StatusOK, map[string]bool{"success": true})
	}
}

func HandleIncrementCommentCount(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			ID   string `json:"id"`
			Type string `json:"type"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		var table string
		switch body.Type {
		case "post":
			table = "community_posts"
		case "question":
			table = "questions"
		default:
			return apis.NewBadRequestError("type must be 'post' or 'question'", nil)
		}

		_, err := app.DB().NewQuery(
			"UPDATE "+table+" SET comment_count = comment_count + 1 WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.ID}).Execute()
		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to increment comment count", err)
		}

		var count int
		_ = app.DB().NewQuery(
			"SELECT comment_count FROM "+table+" WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.ID}).Row(&count)

		return e.JSON(http.StatusOK, map[string]any{
			"success":       true,
			"comment_count": count,
		})
	}
}

func HandleDecrementCommentCount(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			ID   string `json:"id"`
			Type string `json:"type"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		var table string
		switch body.Type {
		case "post":
			table = "community_posts"
		case "question":
			table = "questions"
		default:
			return apis.NewBadRequestError("type must be 'post' or 'question'", nil)
		}

		_, err := app.DB().NewQuery(
			"UPDATE "+table+" SET comment_count = MAX(0, comment_count - 1) WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.ID}).Execute()
		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to decrement comment count", err)
		}

		var count int
		_ = app.DB().NewQuery(
			"SELECT comment_count FROM "+table+" WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.ID}).Row(&count)

		return e.JSON(http.StatusOK, map[string]any{
			"success":       true,
			"comment_count": count,
		})
	}
}

func HandleToggleBookmark(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			PostID     string `json:"post_id"`
			Bookmarked bool   `json:"bookmarked"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.PostID == "" {
			return apis.NewBadRequestError("post_id is required", nil)
		}

		var query string
		if body.Bookmarked {
			query = "UPDATE community_posts SET bookmark_count = bookmark_count + 1 WHERE id = {:id}"
		} else {
			query = "UPDATE community_posts SET bookmark_count = MAX(0, bookmark_count - 1) WHERE id = {:id}"
		}

		_, err := app.DB().NewQuery(query).Bind(dbx.Params{"id": body.PostID}).Execute()
		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to toggle bookmark", err)
		}

		var count int
		_ = app.DB().NewQuery(
			"SELECT bookmark_count FROM community_posts WHERE id = {:id}",
		).Bind(dbx.Params{"id": body.PostID}).Row(&count)

		return e.JSON(http.StatusOK, map[string]any{
			"success":        true,
			"bookmark_count": count,
		})
	}
}
