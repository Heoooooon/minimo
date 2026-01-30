package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func HandleToggleFollow(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		followerId := e.Auth.Id

		var body struct {
			FollowingID string `json:"following_id"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.FollowingID == "" {
			return apis.NewBadRequestError("following_id is required", nil)
		}

		if followerId == body.FollowingID {
			return apis.NewBadRequestError("Cannot follow yourself", nil)
		}

		var following bool

		err := app.RunInTransaction(func(txApp core.App) error {
			existing, _ := txApp.FindFirstRecordByFilter("follows",
				"follower = {:follower} && following = {:following}",
				dbx.Params{"follower": followerId, "following": body.FollowingID},
			)

			if existing != nil {
				if err := txApp.Delete(existing); err != nil {
					return err
				}
				following = false
			} else {
				followsCollection, err := txApp.FindCollectionByNameOrId("follows")
				if err != nil {
					return err
				}
				record := core.NewRecord(followsCollection)
				record.Set("follower", followerId)
				record.Set("following", body.FollowingID)
				if err := txApp.Save(record); err != nil {
					return err
				}
				following = true
			}

			return nil
		})

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to toggle follow", err)
		}

		if following {
			go createFollowNotification(app, followerId, body.FollowingID)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"following": following,
		})
	}
}

func createFollowNotification(app core.App, followerId, followingId string) {
	follower, err := app.FindRecordById("users", followerId)
	if err != nil {
		return
	}
	followerName := follower.GetString("name")
	if followerName == "" {
		followerName = "회원"
	}

	notifCollection, err := app.FindCollectionByNameOrId("notifications")
	if err != nil {
		return
	}
	notif := core.NewRecord(notifCollection)
	notif.Set("user", followingId)
	notif.Set("type", "follow")
	notif.Set("title", "새 팔로워")
	notif.Set("message", followerName+"님이 회원님을 팔로우합니다.")
	notif.Set("target_id", followerId)
	notif.Set("target_type", "user")
	notif.Set("is_read", false)
	notif.Set("actor", followerId)
	_ = app.Save(notif)
}
