package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func HandleToggleCurious(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id

		var body struct {
			QuestionID string `json:"question_id"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.QuestionID == "" {
			return apis.NewBadRequestError("question_id is required", nil)
		}

		var curious bool
		var newCount int

		err := app.RunInTransaction(func(txApp core.App) error {
			existing, _ := txApp.FindFirstRecordByFilter("curious",
				"user_id = {:user} && question_id = {:qid}",
				dbx.Params{"user": userId, "qid": body.QuestionID},
			)

			if existing != nil {
				if err := txApp.Delete(existing); err != nil {
					return err
				}
				_, err := txApp.DB().NewQuery(
					"UPDATE questions SET curious_count = MAX(0, curious_count - 1) WHERE id = {:id}",
				).Bind(dbx.Params{"id": body.QuestionID}).Execute()
				if err != nil {
					return err
				}
				curious = false
			} else {
				curiousCollection, err := txApp.FindCollectionByNameOrId("curious")
				if err != nil {
					return err
				}
				record := core.NewRecord(curiousCollection)
				record.Set("user_id", userId)
				record.Set("question_id", body.QuestionID)
				if err := txApp.Save(record); err != nil {
					return err
				}
				_, err = txApp.DB().NewQuery(
					"UPDATE questions SET curious_count = curious_count + 1 WHERE id = {:id}",
				).Bind(dbx.Params{"id": body.QuestionID}).Execute()
				if err != nil {
					return err
				}
				curious = true
			}

			err := txApp.DB().NewQuery(
				"SELECT curious_count FROM questions WHERE id = {:id}",
			).Bind(dbx.Params{"id": body.QuestionID}).Row(&newCount)
			return err
		})

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to toggle curious", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"curious":       curious,
			"curious_count": newCount,
		})
	}
}
