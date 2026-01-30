package handlers

import (
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

type CommentRow struct {
	ID              string `db:"id" json:"id"`
	PostID          string `db:"post" json:"post"`
	Author          string `db:"author" json:"author"`
	AuthorName      string `db:"author_name" json:"author_name"`
	Content         string `db:"content" json:"content"`
	LikeCount       int    `db:"like_count" json:"like_count"`
	ParentCommentID string `db:"parent_comment" json:"parent_comment"`
	Created         string `db:"created" json:"created"`
	Updated         string `db:"updated" json:"updated"`
	IsLiked         int    `db:"is_liked" json:"-"`
	Depth           int    `db:"depth" json:"-"`
}

type CommentNode struct {
	ID              string        `json:"id"`
	PostID          string        `json:"post"`
	Author          string        `json:"author"`
	AuthorName      string        `json:"author_name"`
	Content         string        `json:"content"`
	LikeCount       int           `json:"like_count"`
	ParentCommentID string        `json:"parent_comment,omitempty"`
	Created         string        `json:"created"`
	Updated         string        `json:"updated"`
	IsLiked         bool          `json:"is_liked"`
	Replies         []CommentNode `json:"replies"`
}

func HandleGetCommentTree(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Auth.Id
		postId := e.Request.PathValue("postId")

		perPage, _ := strconv.Atoi(e.Request.URL.Query().Get("perPage"))
		if perPage < 1 || perPage > 200 {
			perPage = 100
		}

		var rows []CommentRow
		err := app.DB().NewQuery(`
			WITH RECURSIVE comment_tree AS (
				SELECT id, post, author, author_name, content,
					   like_count, parent_comment, created, updated, 0 as depth
				FROM comments
				WHERE post = {:postId} AND (parent_comment IS NULL OR parent_comment = '')
				UNION ALL
				SELECT c.id, c.post, c.author, c.author_name, c.content,
					   c.like_count, c.parent_comment, c.created, c.updated, ct.depth + 1
				FROM comments c
				INNER JOIN comment_tree ct ON c.parent_comment = ct.id
			)
			SELECT ct.*,
				CASE WHEN l.id IS NOT NULL THEN 1 ELSE 0 END as is_liked
			FROM comment_tree ct
			LEFT JOIN likes l
				ON l.target_id = ct.id
				AND l.target_type = 'comment'
				AND l.user = {:userId}
			ORDER BY ct.depth ASC, ct.created ASC
			LIMIT {:limit}
		`).Bind(dbx.Params{
			"postId": postId,
			"userId": userId,
			"limit":  perPage,
		}).All(&rows)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch comments", err)
		}

		tree := buildCommentTree(rows)

		return e.JSON(http.StatusOK, map[string]any{
			"items":      tree,
			"totalItems": len(rows),
		})
	}
}

func buildCommentTree(rows []CommentRow) []CommentNode {
	nodeMap := make(map[string]*CommentNode)
	var roots []CommentNode

	for _, r := range rows {
		node := CommentNode{
			ID:              r.ID,
			PostID:          r.PostID,
			Author:          r.Author,
			AuthorName:      r.AuthorName,
			Content:         r.Content,
			LikeCount:       r.LikeCount,
			ParentCommentID: r.ParentCommentID,
			Created:         r.Created,
			Updated:         r.Updated,
			IsLiked:         r.IsLiked == 1,
			Replies:         []CommentNode{},
		}
		nodeMap[r.ID] = &node
	}

	for _, r := range rows {
		node := nodeMap[r.ID]
		if r.ParentCommentID == "" {
			roots = append(roots, *node)
		} else if parent, ok := nodeMap[r.ParentCommentID]; ok {
			parent.Replies = append(parent.Replies, *node)
		} else {
			roots = append(roots, *node)
		}
	}

	return resolveReplies(roots, nodeMap)
}

func resolveReplies(nodes []CommentNode, nodeMap map[string]*CommentNode) []CommentNode {
	result := make([]CommentNode, len(nodes))
	for i, n := range nodes {
		if latest, ok := nodeMap[n.ID]; ok {
			result[i] = *latest
			if len(result[i].Replies) > 0 {
				result[i].Replies = resolveReplies(result[i].Replies, nodeMap)
			}
		} else {
			result[i] = n
		}
	}
	return result
}
