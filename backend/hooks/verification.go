package hooks

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

// rateLimiter는 이메일별 인증 코드 요청 횟수를 제한합니다.
type rateLimiter struct {
	mu       sync.Mutex
	attempts map[string][]time.Time
}

var limiter = &rateLimiter{
	attempts: make(map[string][]time.Time),
}

const (
	maxAttemptsPerWindow = 5               // 윈도우 내 최대 요청 횟수
	rateLimitWindow      = 10 * time.Minute // Rate limit 윈도우
	maxVerifyAttempts    = 5                // 인증 시도 최대 횟수
	verifyWindow         = 3 * time.Minute  // 인증 시도 윈도우
)

// isRateLimited checks if the given key has exceeded the rate limit.
func (r *rateLimiter) isRateLimited(key string, maxAttempts int, window time.Duration) bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	cutoff := now.Add(-window)

	// 윈도우 밖의 오래된 기록 제거
	var valid []time.Time
	for _, t := range r.attempts[key] {
		if t.After(cutoff) {
			valid = append(valid, t)
		}
	}
	r.attempts[key] = valid

	return len(valid) >= maxAttempts
}

// record adds a new attempt for the given key.
func (r *rateLimiter) record(key string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.attempts[key] = append(r.attempts[key], time.Now())
}

func RegisterVerificationRoutes(app core.App) {
	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		se.Router.POST("/api/custom/send-code", handleSendCode(app))
		se.Router.POST("/api/custom/verify-code", handleVerifyCode(app))
		return se.Next()
	})

	// 매 시간마다 만료된 인증 코드 정리
	app.Cron().MustAdd("cleanup_expired_codes", "0 * * * *", func() {
		cleanupExpiredCodes(app)
	})
}

// cleanupExpiredCodes removes expired or used verification codes.
func cleanupExpiredCodes(app core.App) {
	records, err := app.FindRecordsByFilter(
		"verification_codes",
		"verified = true || expires_at < {:now}",
		"-created",
		500,
		0,
		map[string]any{"now": time.Now().UTC().Format(time.RFC3339)},
	)
	if err != nil {
		log.Printf("[WARN] Failed to find expired codes: %v", err)
		return
	}

	for _, record := range records {
		if err := app.Delete(record); err != nil {
			log.Printf("[WARN] Failed to delete expired code %s: %v", record.Id, err)
		}
	}

	if len(records) > 0 {
		log.Printf("[INFO] Cleaned up %d expired/used verification codes", len(records))
	}
}

func handleSendCode(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			Email string `json:"email"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil || body.Email == "" {
			return apis.NewBadRequestError("이메일이 필요합니다.", nil)
		}

		// Rate limiting: 이메일당 10분에 5회까지
		rateLimitKey := "send:" + body.Email
		if limiter.isRateLimited(rateLimitKey, maxAttemptsPerWindow, rateLimitWindow) {
			return apis.NewTooManyRequestsError("너무 많은 요청입니다. 잠시 후 다시 시도해주세요.", nil)
		}
		limiter.record(rateLimitKey)

		code := fmt.Sprintf("%04d", rand.Intn(9000)+1000)
		expiresAt := time.Now().Add(3 * time.Minute).UTC().Format(time.RFC3339)

		collection, err := app.FindCollectionByNameOrId("verification_codes")
		if err != nil {
			return e.JSON(500, map[string]string{"error": "서버 오류가 발생했습니다."})
		}

		record := core.NewRecord(collection)
		record.Set("email", body.Email)
		record.Set("code", code)
		record.Set("expires_at", expiresAt)
		record.Set("verified", false)

		if err := app.Save(record); err != nil {
			return e.JSON(500, map[string]string{"error": "서버 오류가 발생했습니다."})
		}

		apiKey := os.Getenv("RESEND_API_KEY")
		if apiKey == "" {
			return e.JSON(500, map[string]string{"error": "메일 발송 설정이 완료되지 않았습니다."})
		}

		fromEmail := os.Getenv("RESEND_FROM_EMAIL")
		if fromEmail == "" {
			fromEmail = "우물 <onboarding@resend.dev>"
		}

		htmlContent := `<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 40px 20px;">` +
			`<h1 style="color: #0165FE; font-size: 24px; margin-bottom: 30px;">우물 이메일 인증</h1>` +
			`<p style="font-size: 16px; color: #333; margin-bottom: 20px;">안녕하세요! 우물 회원가입을 위한 인증번호입니다.</p>` +
			`<div style="background: #F5F7FA; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">` +
			`<p style="font-size: 14px; color: #666; margin-bottom: 10px;">인증번호</p>` +
			`<p style="font-size: 36px; font-weight: bold; color: #0165FE; letter-spacing: 8px; margin: 0;">` + code + `</p>` +
			`</div>` +
			`<p style="font-size: 14px; color: #999;">이 인증번호는 3분간 유효합니다.<br>본인이 요청하지 않았다면 이 이메일을 무시해주세요.</p>` +
			`</div>`

		emailPayload, _ := json.Marshal(map[string]any{
			"from":    fromEmail,
			"to":      []string{body.Email},
			"subject": "[우물] 이메일 인증번호",
			"html":    htmlContent,
		})

		req, _ := http.NewRequest("POST", "https://api.resend.com/emails", bytes.NewReader(emailPayload))
		req.Header.Set("Authorization", "Bearer "+apiKey)
		req.Header.Set("Content-Type", "application/json")

		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return e.JSON(500, map[string]string{"error": "메일 발송에 실패했습니다."})
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return e.JSON(500, map[string]string{"error": "메일 발송에 실패했습니다."})
		}

		return e.JSON(200, map[string]any{
			"success": true,
			"message": "인증 코드가 발송되었습니다.",
		})
	}
}

func handleVerifyCode(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		var body struct {
			Email string `json:"email"`
			Code  string `json:"code"`
		}
		if err := json.NewDecoder(e.Request.Body).Decode(&body); err != nil || body.Email == "" || body.Code == "" {
			return apis.NewBadRequestError("이메일과 인증 코드가 필요합니다.", nil)
		}

		// Rate limiting: 인증 시도는 이메일당 3분에 5회까지
		verifyKey := "verify:" + body.Email
		if limiter.isRateLimited(verifyKey, maxVerifyAttempts, verifyWindow) {
			return apis.NewTooManyRequestsError("인증 시도 횟수를 초과했습니다. 잠시 후 다시 시도해주세요.", nil)
		}
		limiter.record(verifyKey)

		record, err := app.FindFirstRecordByFilter("verification_codes",
			"email = {:email} && code = {:code} && verified = false",
			map[string]any{"email": body.Email, "code": body.Code},
		)
		if err != nil || record == nil {
			return apis.NewBadRequestError("유효하지 않은 인증 코드입니다.", nil)
		}

		expiresAt, err := time.Parse(time.RFC3339, record.GetString("expires_at"))
		if err != nil || time.Now().After(expiresAt) {
			_ = app.Delete(record)
			return apis.NewBadRequestError("인증 코드가 만료되었습니다.", nil)
		}

		record.Set("verified", true)
		if err := app.Save(record); err != nil {
			return e.JSON(500, map[string]string{"error": "서버 오류가 발생했습니다."})
		}

		return e.JSON(200, map[string]any{
			"success": true,
			"message": "인증이 완료되었습니다.",
		})
	}
}
