package handlers

import (
	"log"
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

func SetupFTS5(app core.App) error {
	statements := []string{
		`CREATE VIRTUAL TABLE IF NOT EXISTS community_fts USING fts5(
			record_id UNINDEXED,
			record_type UNINDEXED,
			title,
			content,
			tokenize='unicode61'
		)`,

		`CREATE TRIGGER IF NOT EXISTS fts_insert_posts
		AFTER INSERT ON community_posts BEGIN
			INSERT INTO community_fts(record_id, record_type, title, content)
			VALUES (NEW.id, 'post', '', NEW.content);
		END`,
		`CREATE TRIGGER IF NOT EXISTS fts_update_posts
		AFTER UPDATE OF content ON community_posts BEGIN
			DELETE FROM community_fts WHERE record_id = OLD.id AND record_type = 'post';
			INSERT INTO community_fts(record_id, record_type, title, content)
			VALUES (NEW.id, 'post', '', NEW.content);
		END`,
		`CREATE TRIGGER IF NOT EXISTS fts_delete_posts
		AFTER DELETE ON community_posts BEGIN
			DELETE FROM community_fts WHERE record_id = OLD.id AND record_type = 'post';
		END`,

		`CREATE TRIGGER IF NOT EXISTS fts_insert_questions
		AFTER INSERT ON questions BEGIN
			INSERT INTO community_fts(record_id, record_type, title, content)
			VALUES (NEW.id, 'question', NEW.title, NEW.content);
		END`,
		`CREATE TRIGGER IF NOT EXISTS fts_update_questions
		AFTER UPDATE OF title, content ON questions BEGIN
			DELETE FROM community_fts WHERE record_id = OLD.id AND record_type = 'question';
			INSERT INTO community_fts(record_id, record_type, title, content)
			VALUES (NEW.id, 'question', NEW.title, NEW.content);
		END`,
		`CREATE TRIGGER IF NOT EXISTS fts_delete_questions
		AFTER DELETE ON questions BEGIN
			DELETE FROM community_fts WHERE record_id = OLD.id AND record_type = 'question';
		END`,
	}

	for _, stmt := range statements {
		if _, err := app.DB().NewQuery(stmt).Execute(); err != nil {
			log.Printf("[FTS5] Failed: %v (statement: %.80s...)", err, stmt)
			return err
		}
	}

	var postCount, questionCount int
	_ = app.DB().NewQuery("SELECT COUNT(*) FROM community_posts").Row(&postCount)
	_ = app.DB().NewQuery("SELECT COUNT(*) FROM questions").Row(&questionCount)

	var ftsCount int
	_ = app.DB().NewQuery("SELECT COUNT(*) FROM community_fts").Row(&ftsCount)

	if ftsCount == 0 && (postCount > 0 || questionCount > 0) {
		log.Println("[FTS5] Backfilling existing records...")
		app.DB().NewQuery(`
			INSERT INTO community_fts(record_id, record_type, title, content)
			SELECT id, 'post', '', content FROM community_posts
		`).Execute()
		app.DB().NewQuery(`
			INSERT INTO community_fts(record_id, record_type, title, content)
			SELECT id, 'question', title, content FROM questions
		`).Execute()
		log.Println("[FTS5] Backfill complete")
	}

	log.Println("[FTS5] Setup complete")
	return nil
}

type SearchResult struct {
	RecordID   string `db:"record_id" json:"id"`
	RecordType string `db:"record_type" json:"type"`
	Title      string `db:"title" json:"title"`
	Snippet    string `db:"snippet" json:"snippet"`
	Rank       float64 `db:"rank" json:"rank"`
}

func HandleSearch(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()
		query := q.Get("q")
		if query == "" {
			return apis.NewBadRequestError("q parameter is required", nil)
		}

		recordType := q.Get("type")
		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 50 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		typeFilter := ""
		params := dbx.Params{
			"query":  query,
			"limit":  perPage,
			"offset": offset,
		}
		if recordType == "post" || recordType == "question" {
			typeFilter = "AND record_type = {:type}"
			params["type"] = recordType
		}

		var results []SearchResult
		err := app.DB().NewQuery(`
			SELECT
				record_id, record_type, title,
				snippet(community_fts, 3, '<b>', '</b>', '...', 32) as snippet,
				rank
			FROM community_fts
			WHERE community_fts MATCH {:query}
			`+typeFilter+`
			ORDER BY rank
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&results)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Search failed", err)
		}

		if results == nil {
			results = []SearchResult{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":   results,
			"page":    page,
			"perPage": perPage,
		})
	}
}
