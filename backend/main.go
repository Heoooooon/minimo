package main

import (
	"log"

	"minimo-backend/handlers"
	"minimo-backend/hooks"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

func main() {
	app := pocketbase.New()

	hooks.RegisterNotificationHooks(app)
	hooks.RegisterVerificationRoutes(app)

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		if err := handlers.SetupFTS5(app); err != nil {
			log.Printf("[WARN] FTS5 setup failed: %v", err)
		}

		// 컬렉션 스키마 보장 (JS 마이그레이션이 미적용된 필드 추가)
		ensureAutodateFields(app)
		ensureMissingFields(app)

		requireAuth := apis.RequireAuth()

		se.Router.POST("/api/community/toggle-like", handlers.HandleToggleLike(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-curious", handlers.HandleToggleCurious(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-follow", handlers.HandleToggleFollow(app)).Bind(requireAuth)
		se.Router.POST("/api/community/increment-view", handlers.HandleIncrementView(app)).Bind(requireAuth)
		se.Router.POST("/api/community/increment-comment-count", handlers.HandleIncrementCommentCount(app)).Bind(requireAuth)
		se.Router.POST("/api/community/decrement-comment-count", handlers.HandleDecrementCommentCount(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-bookmark", handlers.HandleToggleBookmark(app)).Bind(requireAuth)
		se.Router.POST("/api/community/accept-answer", handlers.HandleAcceptAnswer(app)).Bind(requireAuth)

		se.Router.GET("/api/community/posts", handlers.HandleGetPosts(app)).Bind(requireAuth)
		se.Router.GET("/api/community/posts/{id}", handlers.HandleGetPost(app)).Bind(requireAuth)
		se.Router.GET("/api/community/questions", handlers.HandleGetQuestions(app)).Bind(requireAuth)
		se.Router.GET("/api/community/questions/{id}", handlers.HandleGetQuestion(app)).Bind(requireAuth)

		se.Router.GET("/api/community/comments/{postId}", handlers.HandleGetCommentTree(app)).Bind(requireAuth)
		se.Router.GET("/api/community/search", handlers.HandleSearch(app)).Bind(requireAuth)
		se.Router.GET("/api/community/feed/trending", handlers.HandleTrendingFeed(app)).Bind(requireAuth)

		se.Router.POST("/api/notifications/mark-all-read", handlers.HandleMarkAllRead(app)).Bind(requireAuth)
		se.Router.GET("/api/notifications/unread-count", handlers.HandleUnreadCount(app)).Bind(requireAuth)

		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

// ensureMissingFields adds fields that JS migrations would have added
// but were never executed (jsvm plugin not registered).
func ensureMissingFields(app *pocketbase.PocketBase) {
	// records: add creature relation and record_type select
	if col, err := app.FindCollectionByNameOrId("records"); err == nil {
		modified := false

		if col.Fields.GetByName("creature") == nil {
			col.Fields.Add(&core.RelationField{
				Id:            "relation_creature",
				Name:          "creature",
				Required:      false,
				CollectionId:  "pbc_creatures",
				MaxSelect:     1,
				CascadeDelete: false,
			})
			modified = true
			log.Printf("[INFO] Adding 'creature' field to records")
		}

		if col.Fields.GetByName("record_type") == nil {
			col.Fields.Add(&core.SelectField{
				Id:        "select_record_type",
				Name:      "record_type",
				Required:  false,
				MaxSelect: 1,
				Values:    []string{"todo", "activity", "diary"},
			})
			modified = true
			log.Printf("[INFO] Adding 'record_type' field to records")
		}

		// tags, content를 optional로 변경
		if f, ok := col.Fields.GetByName("tags").(*core.SelectField); ok && f.Required {
			f.Required = false
			modified = true
			log.Printf("[INFO] Making 'tags' field optional in records")
		}
		if f, ok := col.Fields.GetByName("content").(*core.TextField); ok && f.Required {
			f.Required = false
			modified = true
			log.Printf("[INFO] Making 'content' field optional in records")
		}

		if modified {
			if err := app.Save(col); err != nil {
				log.Printf("[WARN] Failed to update records collection: %v", err)
			}
		}
	}

	// questions: category select 값을 한글로 업데이트
	if col, err := app.FindCollectionByNameOrId("questions"); err == nil {
		if f, ok := col.Fields.GetByName("category").(*core.SelectField); ok {
			koreanValues := []string{"수질", "질병", "먹이", "장비", "어종", "수초", "기타"}
			if len(f.Values) > 0 && f.Values[0] != "수질" {
				f.Values = koreanValues
				if err := app.Save(col); err != nil {
					log.Printf("[WARN] Failed to update questions category values: %v", err)
				} else {
					log.Printf("[INFO] Updated questions category to Korean values")
				}
			}
		}
	}
}

func ensureAutodateFields(app *pocketbase.PocketBase) {
	collections := []string{
		"community_posts", "questions", "aquariums", "creatures",
		"creature_memos", "gallery_photos", "records", "schedules",
		"creature_catalog", "creature_catalog_reports", "answers",
		"comments", "follows", "tags", "notifications", "likes",
	}

	for _, name := range collections {
		col, err := app.FindCollectionByNameOrId(name)
		if err != nil {
			continue
		}

		modified := false

		if col.Fields.GetByName("created") == nil {
			col.Fields.Add(&core.AutodateField{
				Id:       "autodate_created",
				Name:     "created",
				OnCreate: true,
				OnUpdate: false,
			})
			modified = true
		}

		if col.Fields.GetByName("updated") == nil {
			col.Fields.Add(&core.AutodateField{
				Id:       "autodate_updated",
				Name:     "updated",
				OnCreate: true,
				OnUpdate: true,
			})
			modified = true
		}

		if modified {
			if err := app.Save(col); err != nil {
				log.Printf("[WARN] Failed to add autodate fields to %s: %v", name, err)
			} else {
				log.Printf("[INFO] Added autodate fields to: %s", name)
			}
		}
	}
}
