package handlers

import (
	"net/http"
	"strconv"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/dbx"
)

// ============================================================
// Struct definitions
// ============================================================

type AdminStatsOverview struct {
	TotalUsers     int `json:"total_users"`
	TotalPosts     int `json:"total_posts"`
	TotalQuestions int `json:"total_questions"`
	PendingReports int `json:"pending_reports"`
	TotalAquariums int `json:"total_aquariums"`
	TotalCreatures int `json:"total_creatures"`
}

type DailyActivity struct {
	Date      string `db:"date" json:"date"`
	Users     int    `db:"users" json:"users"`
	Posts     int    `db:"posts" json:"posts"`
	Questions int    `db:"questions" json:"questions"`
}

type AdminUserItem struct {
	ID          string `db:"id" json:"id"`
	Email       string `db:"email" json:"email"`
	Name        string `db:"name" json:"name"`
	Avatar      string `db:"avatar" json:"avatar"`
	Role        string `db:"role" json:"role"`
	Verified    bool   `json:"verified"`
	VerifiedInt int    `db:"verified" json:"-"`
	Created     string `db:"created" json:"created"`
}

type AdminUserDetail struct {
	ID            string `db:"id" json:"id"`
	Email         string `db:"email" json:"email"`
	Name          string `db:"name" json:"name"`
	Avatar        string `db:"avatar" json:"avatar"`
	Role          string `db:"role" json:"role"`
	Verified      bool   `json:"verified"`
	VerifiedInt   int    `db:"verified" json:"-"`
	Created       string `db:"created" json:"created"`
	Updated       string `db:"updated" json:"updated"`
	AquariumCount int    `json:"aquarium_count"`
	PostCount     int    `json:"post_count"`
	QuestionCount int    `json:"question_count"`
	ReportCount   int    `json:"report_count"`
}

type AdminPostItem struct {
	ID           string `db:"id" json:"id"`
	Owner        string `db:"owner" json:"owner"`
	AuthorName   string `db:"author_name" json:"author_name"`
	Content      string `db:"content" json:"content"`
	LikeCount    int    `db:"like_count" json:"like_count"`
	CommentCount int    `db:"comment_count" json:"comment_count"`
	Status       string `db:"status" json:"status"`
	Created      string `db:"created" json:"created"`
}

type AdminQuestionItem struct {
	ID          string `db:"id" json:"id"`
	Owner       string `db:"owner" json:"owner"`
	AuthorName  string `db:"author_name" json:"author_name"`
	Title       string `db:"title" json:"title"`
	Category    string `db:"category" json:"category"`
	AnswerCount int    `db:"answer_count" json:"answer_count"`
	Status      string `db:"status" json:"status"`
	Created     string `db:"created" json:"created"`
}

type AdminReportItem struct {
	ID           string `db:"id" json:"id"`
	Reporter     string `db:"reporter" json:"reporter"`
	ReporterName string `db:"reporter_name" json:"reporter_name"`
	TargetID     string `db:"target_id" json:"target_id"`
	TargetType   string `db:"target_type" json:"target_type"`
	Reason       string `db:"reason" json:"reason"`
	Status       string `db:"status" json:"status"`
	Created      string `db:"created" json:"created"`
}

type AdminReportDetail struct {
	ID           string `db:"id" json:"id"`
	Reporter     string `db:"reporter" json:"reporter"`
	ReporterName string `db:"reporter_name" json:"reporter_name"`
	TargetID     string `db:"target_id" json:"target_id"`
	TargetType   string `db:"target_type" json:"target_type"`
	Reason       string `db:"reason" json:"reason"`
	Detail       string `db:"detail" json:"detail"`
	Status       string `db:"status" json:"status"`
	ResolvedBy   string `db:"resolved_by" json:"resolved_by"`
	ActionTaken  string `db:"action_taken" json:"action_taken"`
	AdminNote    string `db:"admin_note" json:"admin_note"`
	Created      string `db:"created" json:"created"`
	Updated      string `db:"updated" json:"updated"`
}

type AdminCatalogItem struct {
	ID             string `db:"id" json:"id"`
	Reporter       string `db:"reporter" json:"reporter"`
	ReporterName   string `db:"reporter_name" json:"reporter_name"`
	CommonName     string `db:"common_name" json:"common_name"`
	ScientificName string `db:"scientific_name" json:"scientific_name"`
	Status         string `db:"status" json:"status"`
	Created        string `db:"created" json:"created"`
}

// ============================================================
// 1. HandleAdminStatsOverview
// GET /api/admin/stats/overview
// ============================================================

func HandleAdminStatsOverview(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var stats AdminStatsOverview

		var totalUsers int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM users").Row(&totalUsers)
		stats.TotalUsers = totalUsers

		var totalPosts int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM community_posts").Row(&totalPosts)
		stats.TotalPosts = totalPosts

		var totalQuestions int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM questions").Row(&totalQuestions)
		stats.TotalQuestions = totalQuestions

		var pendingReports int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM reports WHERE status = 'pending'").Row(&pendingReports)
		stats.PendingReports = pendingReports

		var totalAquariums int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM aquariums").Row(&totalAquariums)
		stats.TotalAquariums = totalAquariums

		var totalCreatures int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM creatures").Row(&totalCreatures)
		stats.TotalCreatures = totalCreatures

		return e.JSON(http.StatusOK, stats)
	}
}

// ============================================================
// 2. HandleAdminStatsActivity
// GET /api/admin/stats/activity?days=7
// ============================================================

func HandleAdminStatsActivity(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		days, _ := strconv.Atoi(q.Get("days"))
		if days < 1 || days > 365 {
			days = 7
		}

		var activities []DailyActivity
		err := app.DB().NewQuery(`
			WITH RECURSIVE dates(date) AS (
				SELECT date('now', '-' || {:days} || ' days')
				UNION ALL
				SELECT date(date, '+1 day') FROM dates WHERE date < date('now')
			)
			SELECT
				d.date,
				COALESCE(u.cnt, 0) as users,
				COALESCE(p.cnt, 0) as posts,
				COALESCE(q.cnt, 0) as questions
			FROM dates d
			LEFT JOIN (SELECT date(created) as dt, COUNT(*) as cnt FROM users GROUP BY dt) u ON u.dt = d.date
			LEFT JOIN (SELECT date(created) as dt, COUNT(*) as cnt FROM community_posts GROUP BY dt) p ON p.dt = d.date
			LEFT JOIN (SELECT date(created) as dt, COUNT(*) as cnt FROM questions GROUP BY dt) q ON q.dt = d.date
			ORDER BY d.date
		`).Bind(dbx.Params{
			"days": days,
		}).All(&activities)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch activity stats", err)
		}

		if activities == nil {
			activities = []DailyActivity{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items": activities,
			"days":  days,
		})
	}
}

// ============================================================
// 3. HandleAdminGetUsers
// GET /api/admin/users?page=1&perPage=20&search=&role=&status=
// ============================================================

func HandleAdminGetUsers(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		search := q.Get("search")
		role := q.Get("role")

		whereClause := ""
		params := dbx.Params{
			"limit":  perPage,
			"offset": offset,
		}

		conditions := []string{}
		if search != "" {
			conditions = append(conditions, "(u.name LIKE {:search} OR u.email LIKE {:search})")
			params["search"] = "%" + search + "%"
		}
		if role != "" {
			conditions = append(conditions, "u.role = {:role}")
			params["role"] = role
		}

		if len(conditions) > 0 {
			whereClause = "WHERE "
			for i, c := range conditions {
				if i > 0 {
					whereClause += " AND "
				}
				whereClause += c
			}
		}

		var users []AdminUserItem
		err := app.DB().NewQuery(`
			SELECT
				u.id, u.email, u.name, u.avatar, u.role,
				u.verified, u.created
			FROM users u
			` + whereClause + `
			ORDER BY u.created DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&users)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch users", err)
		}

		var total int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM users u " + whereClause).Bind(params).Row(&total)

		for i := range users {
			users[i].Verified = users[i].VerifiedInt == 1
		}

		if users == nil {
			users = []AdminUserItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      users,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

// ============================================================
// 4. HandleAdminGetUser
// GET /api/admin/users/{id}
// ============================================================

func HandleAdminGetUser(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Request.PathValue("id")

		var user AdminUserDetail
		err := app.DB().NewQuery(`
			SELECT
				u.id, u.email, u.name, u.avatar, u.role,
				u.verified, u.created, u.updated
			FROM users u
			WHERE u.id = {:userId}
		`).Bind(dbx.Params{
			"userId": userId,
		}).One(&user)

		if err != nil {
			return apis.NewNotFoundError("User not found", err)
		}

		user.Verified = user.VerifiedInt == 1

		var aquariumCount int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM aquariums WHERE owner = {:userId}").Bind(dbx.Params{
			"userId": userId,
		}).Row(&aquariumCount)
		user.AquariumCount = aquariumCount

		var postCount int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM community_posts WHERE owner = {:userId}").Bind(dbx.Params{
			"userId": userId,
		}).Row(&postCount)
		user.PostCount = postCount

		var questionCount int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM questions WHERE owner = {:userId}").Bind(dbx.Params{
			"userId": userId,
		}).Row(&questionCount)
		user.QuestionCount = questionCount

		var reportCount int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM reports WHERE reporter = {:userId}").Bind(dbx.Params{
			"userId": userId,
		}).Row(&reportCount)
		user.ReportCount = reportCount

		return e.JSON(http.StatusOK, user)
	}
}

// ============================================================
// 5. HandleAdminUpdateUserRole
// PATCH /api/admin/users/{id}/role
// ============================================================

func HandleAdminUpdateUserRole(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Request.PathValue("id")

		var body struct {
			Role string `json:"role"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.Role != "admin" && body.Role != "user" {
			return apis.NewBadRequestError("Role must be 'admin' or 'user'", nil)
		}

		record, err := app.FindRecordById("users", userId)
		if err != nil {
			return apis.NewNotFoundError("User not found", err)
		}

		record.Set("role", body.Role)
		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to update user role", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "User role updated",
			"id":      userId,
			"role":    body.Role,
		})
	}
}

// ============================================================
// 6. HandleAdminUpdateUserStatus
// PATCH /api/admin/users/{id}/status
// ============================================================

func HandleAdminUpdateUserStatus(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		userId := e.Request.PathValue("id")

		var body struct {
			Verified bool `json:"verified"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		record, err := app.FindRecordById("users", userId)
		if err != nil {
			return apis.NewNotFoundError("User not found", err)
		}

		record.Set("verified", body.Verified)
		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to update user status", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message":  "User status updated",
			"id":       userId,
			"verified": body.Verified,
		})
	}
}

// ============================================================
// 7. HandleAdminGetPosts
// GET /api/admin/posts?page=1&perPage=20&search=&status=
// ============================================================

func HandleAdminGetPosts(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		search := q.Get("search")
		status := q.Get("status")

		whereClause := ""
		params := dbx.Params{
			"limit":  perPage,
			"offset": offset,
		}

		conditions := []string{}
		if search != "" {
			conditions = append(conditions, "p.content LIKE {:search}")
			params["search"] = "%" + search + "%"
		}
		if status != "" {
			conditions = append(conditions, "p.status = {:status}")
			params["status"] = status
		}

		if len(conditions) > 0 {
			whereClause = "WHERE "
			for i, c := range conditions {
				if i > 0 {
					whereClause += " AND "
				}
				whereClause += c
			}
		}

		var posts []AdminPostItem
		err := app.DB().NewQuery(`
			SELECT
				p.id, p.owner,
				COALESCE(u.name, '') as author_name,
				p.content, p.like_count, p.comment_count,
				COALESCE(p.status, 'active') as status,
				p.created
			FROM community_posts p
			LEFT JOIN users u ON u.id = p.owner
			` + whereClause + `
			ORDER BY p.created DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&posts)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch posts", err)
		}

		var total int
		_ = app.DB().NewQuery(`
			SELECT COUNT(*) FROM community_posts p
			LEFT JOIN users u ON u.id = p.owner
			` + whereClause).Bind(params).Row(&total)

		if posts == nil {
			posts = []AdminPostItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      posts,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

// ============================================================
// 8. HandleAdminUpdatePostStatus
// PATCH /api/admin/posts/{id}/status
// ============================================================

func HandleAdminUpdatePostStatus(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		postId := e.Request.PathValue("id")

		var body struct {
			Status string `json:"status"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.Status != "active" && body.Status != "hidden" && body.Status != "deleted" {
			return apis.NewBadRequestError("Status must be 'active', 'hidden', or 'deleted'", nil)
		}

		record, err := app.FindRecordById("community_posts", postId)
		if err != nil {
			return apis.NewNotFoundError("Post not found", err)
		}

		record.Set("status", body.Status)
		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to update post status", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "Post status updated",
			"id":      postId,
			"status":  body.Status,
		})
	}
}

// ============================================================
// 9. HandleAdminGetQuestions
// GET /api/admin/questions?page=1&perPage=20&search=&status=
// ============================================================

func HandleAdminGetQuestions(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		search := q.Get("search")
		status := q.Get("status")

		whereClause := ""
		params := dbx.Params{
			"limit":  perPage,
			"offset": offset,
		}

		conditions := []string{}
		if search != "" {
			conditions = append(conditions, "(q.title LIKE {:search} OR q.content LIKE {:search})")
			params["search"] = "%" + search + "%"
		}
		if status != "" {
			conditions = append(conditions, "q.status = {:status}")
			params["status"] = status
		}

		if len(conditions) > 0 {
			whereClause = "WHERE "
			for i, c := range conditions {
				if i > 0 {
					whereClause += " AND "
				}
				whereClause += c
			}
		}

		var questions []AdminQuestionItem
		err := app.DB().NewQuery(`
			SELECT
				q.id, q.owner,
				COALESCE(u.name, '') as author_name,
				q.title, q.category,
				COALESCE(q.answer_count, 0) as answer_count,
				COALESCE(q.status, 'active') as status,
				q.created
			FROM questions q
			LEFT JOIN users u ON u.id = q.owner
			` + whereClause + `
			ORDER BY q.created DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&questions)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch questions", err)
		}

		var total int
		_ = app.DB().NewQuery(`
			SELECT COUNT(*) FROM questions q
			LEFT JOIN users u ON u.id = q.owner
			` + whereClause).Bind(params).Row(&total)

		if questions == nil {
			questions = []AdminQuestionItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      questions,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

// ============================================================
// 10. HandleAdminUpdateQuestionStatus
// PATCH /api/admin/questions/{id}/status
// ============================================================

func HandleAdminUpdateQuestionStatus(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		questionId := e.Request.PathValue("id")

		var body struct {
			Status string `json:"status"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.Status != "active" && body.Status != "hidden" && body.Status != "deleted" {
			return apis.NewBadRequestError("Status must be 'active', 'hidden', or 'deleted'", nil)
		}

		record, err := app.FindRecordById("questions", questionId)
		if err != nil {
			return apis.NewNotFoundError("Question not found", err)
		}

		record.Set("status", body.Status)
		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to update question status", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "Question status updated",
			"id":      questionId,
			"status":  body.Status,
		})
	}
}

// ============================================================
// 11. HandleAdminDeleteComment
// DELETE /api/admin/comments/{id}
// ============================================================

func HandleAdminDeleteComment(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		commentId := e.Request.PathValue("id")

		record, err := app.FindRecordById("comments", commentId)
		if err != nil {
			return apis.NewNotFoundError("Comment not found", err)
		}

		if err := app.Delete(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to delete comment", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "Comment deleted",
			"id":      commentId,
		})
	}
}

// ============================================================
// 12. HandleAdminDeleteAnswer
// DELETE /api/admin/answers/{id}
// ============================================================

func HandleAdminDeleteAnswer(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		answerId := e.Request.PathValue("id")

		record, err := app.FindRecordById("answers", answerId)
		if err != nil {
			return apis.NewNotFoundError("Answer not found", err)
		}

		if err := app.Delete(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to delete answer", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "Answer deleted",
			"id":      answerId,
		})
	}
}

// ============================================================
// 13. HandleAdminGetReports
// GET /api/admin/reports?page=1&perPage=20&status=pending
// ============================================================

func HandleAdminGetReports(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		status := q.Get("status")

		whereClause := ""
		params := dbx.Params{
			"limit":  perPage,
			"offset": offset,
		}

		if status != "" {
			whereClause = "WHERE r.status = {:status}"
			params["status"] = status
		}

		var reports []AdminReportItem
		err := app.DB().NewQuery(`
			SELECT
				r.id, r.reporter,
				COALESCE(u.name, '') as reporter_name,
				r.target_id, r.target_type,
				COALESCE(r.reason, '') as reason,
				COALESCE(r.status, 'pending') as status,
				r.created
			FROM reports r
			LEFT JOIN users u ON u.id = r.reporter
			` + whereClause + `
			ORDER BY r.created DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(params).All(&reports)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch reports", err)
		}

		var total int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM reports r " + whereClause).Bind(params).Row(&total)

		if reports == nil {
			reports = []AdminReportItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      reports,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

// ============================================================
// 14. HandleAdminGetReport
// GET /api/admin/reports/{id}
// ============================================================

func HandleAdminGetReport(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		reportId := e.Request.PathValue("id")

		var report AdminReportDetail
		err := app.DB().NewQuery(`
			SELECT
				r.id, r.reporter,
				COALESCE(u.name, '') as reporter_name,
				r.target_id, r.target_type,
				COALESCE(r.reason, '') as reason,
				COALESCE(r.detail, '') as detail,
				COALESCE(r.status, 'pending') as status,
				COALESCE(r.resolved_by, '') as resolved_by,
				COALESCE(r.action_taken, '') as action_taken,
				COALESCE(r.admin_note, '') as admin_note,
				r.created, r.updated
			FROM reports r
			LEFT JOIN users u ON u.id = r.reporter
			WHERE r.id = {:reportId}
		`).Bind(dbx.Params{
			"reportId": reportId,
		}).One(&report)

		if err != nil {
			return apis.NewNotFoundError("Report not found", err)
		}

		return e.JSON(http.StatusOK, report)
	}
}

// ============================================================
// 15. HandleAdminResolveReport
// PATCH /api/admin/reports/{id}/resolve
// ============================================================

func HandleAdminResolveReport(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		reportId := e.Request.PathValue("id")

		var body struct {
			Action    string `json:"action"`
			AdminNote string `json:"admin_note"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		if body.Action != "warning" && body.Action != "delete" && body.Action != "block" && body.Action != "none" {
			return apis.NewBadRequestError("Action must be 'warning', 'delete', 'block', or 'none'", nil)
		}

		record, err := app.FindRecordById("reports", reportId)
		if err != nil {
			return apis.NewNotFoundError("Report not found", err)
		}

		record.Set("status", "resolved")
		record.Set("resolved_by", e.Auth.Id)
		record.Set("action_taken", body.Action)
		record.Set("admin_note", body.AdminNote)
		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to resolve report", err)
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message":      "Report resolved",
			"id":           reportId,
			"status":       "resolved",
			"action_taken": body.Action,
		})
	}
}

// ============================================================
// 16. HandleAdminGetPendingCatalog
// GET /api/admin/catalog/pending?page=1&perPage=20
// ============================================================

func HandleAdminGetPendingCatalog(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		q := e.Request.URL.Query()

		page, _ := strconv.Atoi(q.Get("page"))
		if page < 1 {
			page = 1
		}
		perPage, _ := strconv.Atoi(q.Get("perPage"))
		if perPage < 1 || perPage > 100 {
			perPage = 20
		}
		offset := (page - 1) * perPage

		var items []AdminCatalogItem
		err := app.DB().NewQuery(`
			SELECT
				c.id, c.reporter,
				COALESCE(u.name, '') as reporter_name,
				COALESCE(c.common_name, '') as common_name,
				COALESCE(c.scientific_name, '') as scientific_name,
				COALESCE(c.status, 'pending') as status,
				c.created
			FROM creature_catalog_reports c
			LEFT JOIN users u ON u.id = c.reporter
			WHERE c.status = 'pending'
			ORDER BY c.created DESC
			LIMIT {:limit} OFFSET {:offset}
		`).Bind(dbx.Params{
			"limit":  perPage,
			"offset": offset,
		}).All(&items)

		if err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to fetch pending catalog items", err)
		}

		var total int
		_ = app.DB().NewQuery("SELECT COUNT(*) FROM creature_catalog_reports WHERE status = 'pending'").Row(&total)

		if items == nil {
			items = []AdminCatalogItem{}
		}

		return e.JSON(http.StatusOK, map[string]any{
			"items":      items,
			"page":       page,
			"perPage":    perPage,
			"totalItems": total,
			"totalPages": (total + perPage - 1) / perPage,
		})
	}
}

// ============================================================
// 17. HandleAdminApproveCatalog
// PATCH /api/admin/catalog/{id}/approve
// ============================================================

func HandleAdminApproveCatalog(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		catalogId := e.Request.PathValue("id")

		var body struct {
			Approved bool `json:"approved"`
		}
		if err := e.BindBody(&body); err != nil {
			return apis.NewBadRequestError("Invalid request body", err)
		}

		record, err := app.FindRecordById("creature_catalog_reports", catalogId)
		if err != nil {
			return apis.NewNotFoundError("Catalog report not found", err)
		}

		if body.Approved {
			record.Set("status", "approved")
		} else {
			record.Set("status", "rejected")
		}

		if err := app.Save(record); err != nil {
			return apis.NewApiError(http.StatusInternalServerError, "Failed to update catalog report", err)
		}

		status := "rejected"
		if body.Approved {
			status = "approved"
		}

		return e.JSON(http.StatusOK, map[string]any{
			"message": "Catalog report updated",
			"id":      catalogId,
			"status":  status,
		})
	}
}
