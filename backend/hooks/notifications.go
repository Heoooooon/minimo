package hooks

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/pocketbase/pocketbase/core"
)

func RegisterNotificationHooks(app core.App) {
	app.OnRecordAfterCreateSuccess("notifications").BindFunc(func(e *core.RecordEvent) error {
		go sendFCMPush(app, e.Record)
		return e.Next()
	})

	app.OnRecordAfterCreateSuccess("answers").BindFunc(func(e *core.RecordEvent) error {
		go handleAnswerNotification(app, e.Record)
		return e.Next()
	})

	app.OnRecordAfterCreateSuccess("comments").BindFunc(func(e *core.RecordEvent) error {
		go handleCommentNotification(app, e.Record)
		return e.Next()
	})

	app.OnRecordAfterCreateSuccess("follows").BindFunc(func(e *core.RecordEvent) error {
		go handleFollowNotification(app, e.Record)
		return e.Next()
	})

	app.OnRecordAfterDeleteSuccess("likes").BindFunc(func(e *core.RecordEvent) error {
		go handleLikeDelete(app, e.Record)
		return e.Next()
	})
}

func sendFCMPush(app core.App, notification *core.Record) {
	pushURL := os.Getenv("PUSH_FUNCTION_URL")
	webhookSecret := os.Getenv("WEBHOOK_SECRET")
	if pushURL == "" {
		return
	}

	userId := notification.GetString("user")
	if userId == "" {
		return
	}

	user, err := app.FindRecordById("users", userId)
	if err != nil {
		return
	}
	fcmToken := user.GetString("fcm_token")
	if fcmToken == "" {
		return
	}

	payload := map[string]any{
		"fcmToken": fcmToken,
		"title":    notification.GetString("title"),
		"body":     notification.GetString("message"),
		"data": map[string]string{
			"type":            notification.GetString("type"),
			"target_id":       notification.GetString("target_id"),
			"target_type":     notification.GetString("target_type"),
			"notification_id": notification.Id,
		},
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return
	}

	req, err := http.NewRequest("POST", pushURL, bytes.NewReader(body))
	if err != nil {
		return
	}
	req.Header.Set("Content-Type", "application/json")
	if webhookSecret != "" {
		req.Header.Set("Authorization", "Bearer "+webhookSecret)
	}

	client := &http.Client{Timeout: 15 * 1e9}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[FCM] Push error: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		log.Printf("[FCM] Push failed: status %d", resp.StatusCode)
	}
}

func handleAnswerNotification(app core.App, answer *core.Record) {
	questionId := answer.GetString("question")
	if questionId == "" {
		return
	}

	question, err := app.FindRecordById("questions", questionId)
	if err != nil {
		return
	}

	authorId := question.GetString("owner")
	answererID := answer.GetString("author")
	if authorId == "" || authorId == answererID {
		return
	}

	createNotification(app, authorId, "answer", "새 답변",
		"회원님의 질문에 새 답변이 달렸습니다.",
		questionId, "question", answererID)
}

func handleCommentNotification(app core.App, comment *core.Record) {
	postId := comment.GetString("post")
	if postId == "" {
		return
	}

	post, err := app.FindRecordById("community_posts", postId)
	if err != nil {
		return
	}

	authorId := post.GetString("owner")
	commenterId := comment.GetString("author")
	if authorId == "" || authorId == commenterId {
		return
	}

	createNotification(app, authorId, "comment", "새 댓글",
		"회원님의 게시글에 새 댓글이 달렸습니다.",
		postId, "post", commenterId)
}

func handleFollowNotification(app core.App, follow *core.Record) {
	followingId := follow.GetString("following")
	followerId := follow.GetString("follower")
	if followingId == "" || followerId == "" {
		return
	}

	follower, err := app.FindRecordById("users", followerId)
	if err != nil {
		return
	}
	followerName := follower.GetString("name")
	if followerName == "" {
		followerName = "회원"
	}

	createNotification(app, followingId, "follow", "새 팔로워",
		followerName+"님이 회원님을 팔로우합니다.",
		followerId, "user", followerId)
}

func handleLikeDelete(app core.App, like *core.Record) {
	targetId := like.GetString("target_id")
	targetType := like.GetString("target_type")
	if targetId == "" || targetType == "" {
		return
	}

	collectionMap := map[string]string{
		"post":    "community_posts",
		"comment": "comments",
		"answer":  "answers",
	}
	collectionName, ok := collectionMap[targetType]
	if !ok {
		return
	}

	target, err := app.FindRecordById(collectionName, targetId)
	if err != nil {
		return
	}

	currentCount := target.GetInt("like_count")
	newCount := currentCount - 1
	if newCount < 0 {
		newCount = 0
	}
	target.Set("like_count", newCount)
	_ = app.Save(target)
}

func createNotification(app core.App, userId, notifType, title, message, targetId, targetType, actorId string) {
	collection, err := app.FindCollectionByNameOrId("notifications")
	if err != nil {
		log.Printf("[Notification] Collection not found: %v", err)
		return
	}

	record := core.NewRecord(collection)
	record.Set("user", userId)
	record.Set("type", notifType)
	record.Set("title", title)
	record.Set("message", message)
	record.Set("target_id", targetId)
	record.Set("target_type", targetType)
	record.Set("is_read", false)
	record.Set("actor", actorId)

	if err := app.Save(record); err != nil {
		log.Printf("[Notification] Failed to create: %v", err)
	}
}
