package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func HandleAcceptAnswer(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id

		var body struct {
			AnswerID string `json:"answer_id"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}
		if body.AnswerID == "" {
			return apis.NewBadRequestError("answer_id is required", nil)
		}

		// 답변 조회
		answer, err := app.FindRecordById("answers", body.AnswerID)
		if err != nil {
			return apis.NewNotFoundError("Answer not found", err)
		}

		questionId := answer.GetString("question")
		answerAuthorId := answer.GetString("author")

		// 질문 조회
		question, err := app.FindRecordById("questions", questionId)
		if err != nil {
			return apis.NewNotFoundError("Question not found", err)
		}

		questionOwnerId := question.GetString("owner")

		// 질문 작성자만 채택 가능
		if userId != questionOwnerId {
			return apis.NewForbiddenError("Only the question author can accept an answer", nil)
		}

		// 본인 답변은 채택 불가
		if answerAuthorId == userId {
			return apis.NewBadRequestError("You cannot accept your own answer", nil)
		}

		// 기존 채택 해제 + 새 채택을 트랜잭션으로 처리
		err = app.RunInTransaction(func(txApp core.App) error {
			// 같은 질문의 기존 채택된 답변 해제
			_, dbErr := txApp.DB().NewQuery(
				"UPDATE answers SET is_accepted = false WHERE question = {:qid} AND is_accepted = true",
			).Bind(dbx.Params{"qid": questionId}).Execute()
			if dbErr != nil {
				return dbErr
			}

			// 새 답변 채택
			answer.Set("is_accepted", true)
			return txApp.Save(answer)
		})

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to accept answer", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"success":   true,
			"answer_id": body.AnswerID,
		})
	}
}
