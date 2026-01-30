package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

var targetTypeToCollection = map[string]string{
	"post":    "community_posts",
	"comment": "comments",
	"answer":  "answers",
}

func HandleToggleLike(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id

		var body struct {
			TargetID   string `json:"target_id"`
			TargetType string `json:"target_type"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.TargetID == "" || body.TargetType == "" {
			return apis.NewBadRequestError("target_id and target_type are required", nil)
		}

		collectionName, ok := targetTypeToCollection[body.TargetType]
		if !ok {
			return apis.NewBadRequestError("Invalid target_type", nil)
		}

		var liked bool
		var newCount int

		err := app.RunInTransaction(func(txApp core.App) error {
			existing, _ := txApp.FindFirstRecordByFilter("likes",
				"user = {:user} && target_id = {:tid} && target_type = {:tt}",
				dbx.Params{"user": userId, "tid": body.TargetID, "tt": body.TargetType},
			)

			if existing != nil {
				if err := txApp.Delete(existing); err != nil {
					return err
				}
				_, err := txApp.DB().NewQuery(
					"UPDATE " + collectionName + " SET like_count = MAX(0, like_count - 1) WHERE id = {:id}",
				).Bind(dbx.Params{"id": body.TargetID}).Execute()
				if err != nil {
					return err
				}
				liked = false
			} else {
				likesCollection, err := txApp.FindCollectionByNameOrId("likes")
				if err != nil {
					return err
				}
				record := core.NewRecord(likesCollection)
				record.Set("user", userId)
				record.Set("target_id", body.TargetID)
				record.Set("target_type", body.TargetType)
				if err := txApp.Save(record); err != nil {
					return err
				}
				_, err = txApp.DB().NewQuery(
					"UPDATE "+collectionName+" SET like_count = like_count + 1 WHERE id = {:id}",
				).Bind(dbx.Params{"id": body.TargetID}).Execute()
				if err != nil {
					return err
				}
				liked = true
			}

			err := txApp.DB().NewQuery(
				"SELECT like_count FROM "+collectionName+" WHERE id = {:id}",
			).Bind(dbx.Params{"id": body.TargetID}).Row(&newCount)
			return err
		})

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to toggle like", err)
		}

		if liked {
			go createLikeNotification(app, userId, body.TargetID, body.TargetType, collectionName)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"liked":      liked,
			"like_count": newCount,
		})
	}
}

func createLikeNotification(app core.App, userId, targetId, targetType, collectionName string) {
	target, err := app.FindRecordById(collectionName, targetId)
	if err != nil {
		return
	}

	authorId := target.GetString("author")
	if authorId == "" {
		authorId = target.GetString("owner")
	}
	if authorId == "" || authorId == userId {
		return
	}

	liker, err := app.FindRecordById("users", userId)
	if err != nil {
		return
	}
	likerName := liker.GetString("name")
	if likerName == "" {
		likerName = "회원"
	}

	var message, notifTargetType, notifTargetId string
	switch targetType {
	case "post":
		message = likerName + "님이 회원님의 게시글을 좋아합니다."
		notifTargetType = "post"
		notifTargetId = targetId
	case "comment":
		message = likerName + "님이 회원님의 댓글을 좋아합니다."
		postId := target.GetString("post")
		if postId != "" {
			notifTargetType = "post"
			notifTargetId = postId
		} else {
			notifTargetType = "comment"
			notifTargetId = targetId
		}
	case "answer":
		message = likerName + "님이 회원님의 답변을 좋아합니다."
		questionId := target.GetString("question")
		if questionId != "" {
			notifTargetType = "question"
			notifTargetId = questionId
		} else {
			notifTargetType = "answer"
			notifTargetId = targetId
		}
	}

	notifCollection, err := app.FindCollectionByNameOrId("notifications")
	if err != nil {
		return
	}
	notif := core.NewRecord(notifCollection)
	notif.Set("user", authorId)
	notif.Set("type", "like")
	notif.Set("title", "좋아요")
	notif.Set("message", message)
	notif.Set("target_id", notifTargetId)
	notif.Set("target_type", notifTargetType)
	notif.Set("is_read", false)
	notif.Set("actor", userId)
	_ = app.Save(notif)
}
