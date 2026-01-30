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

		requireAuth := apis.RequireAuth()

		se.Router.POST("/api/community/toggle-like", handlers.HandleToggleLike(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-curious", handlers.HandleToggleCurious(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-follow", handlers.HandleToggleFollow(app)).Bind(requireAuth)
		se.Router.POST("/api/community/increment-view", handlers.HandleIncrementView(app)).Bind(requireAuth)
		se.Router.POST("/api/community/increment-comment-count", handlers.HandleIncrementCommentCount(app)).Bind(requireAuth)
		se.Router.POST("/api/community/decrement-comment-count", handlers.HandleDecrementCommentCount(app)).Bind(requireAuth)
		se.Router.POST("/api/community/toggle-bookmark", handlers.HandleToggleBookmark(app)).Bind(requireAuth)

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
