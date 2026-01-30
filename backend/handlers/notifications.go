package handlers

import (
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func HandleMarkAllRead(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id

		result, err := app.DB().NewQuery(
			"UPDATE notifications SET is_read = 1 WHERE user = {:userId} AND is_read = 0",
		).Bind(dbx.Params{"userId": userId}).Execute()

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to mark notifications", err)
		}

		affected, _ := result.RowsAffected()

		return e.JSON(http.StatusOK, map[string]any{
			"success": true,
			"count":   affected,
		})
	}
}

func HandleUnreadCount(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id

		var count int
		err := app.DB().NewQuery(
			"SELECT COUNT(*) FROM notifications WHERE user = {:userId} AND is_read = 0",
		).Bind(dbx.Params{"userId": userId}).Row(&count)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to count notifications", err)
		}

		return e.JSON(http.StatusOK, map[string]int{"count": count})
	}
}
