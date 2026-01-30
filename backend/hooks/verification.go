package hooks

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

func RegisterVerificationRoutes(app core.App) {
	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		se.Router.GET("/api/custom/debug", handleDebug(app))
		se.Router.POST("/api/custom/send-code", handleSendCode(app))
		se.Router.POST("/api/custom/verify-code", handleVerifyCode(app))
		return se.Next()
	})
}

func handleDebug(app core.App) func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		collection, err := app.FindCollectionByNameOrId("verification_codes")
		if err != nil {
			return e.JSON(500, map[string]string{"error": err.Error()})
		}

		fieldNames := []string{}
		for _, f := range collection.Fields {
			fieldNames = append(fieldNames, f.GetName())
		}

		return e.JSON(200, map[string]any{
			"collectionName": collection.Name,
			"collectionId":   collection.Id,
			"fieldNames":     fieldNames,
		})
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

		code := fmt.Sprintf("%04d", rand.Intn(9000)+1000)
		expiresAt := time.Now().Add(3 * time.Minute).UTC().Format(time.RFC3339)

		collection, err := app.FindCollectionByNameOrId("verification_codes")
		if err != nil {
			return e.JSON(500, map[string]string{"error": err.Error()})
		}

		record := core.NewRecord(collection)
		record.Set("email", body.Email)
		record.Set("code", code)
		record.Set("expires_at", expiresAt)
		record.Set("verified", false)

		if err := app.Save(record); err != nil {
			return e.JSON(500, map[string]string{"error": err.Error()})
		}

		apiKey := os.Getenv("RESEND_API_KEY")
		if apiKey == "" {
			return e.JSON(500, map[string]string{"error": "RESEND_API_KEY 환경변수가 설정되지 않았습니다."})
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
			return e.JSON(500, map[string]string{"error": err.Error(), "message": "Failed"})
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			return e.JSON(500, map[string]string{
				"error":   fmt.Sprintf("Resend API 에러 (status %d)", resp.StatusCode),
				"message": "Failed",
			})
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
			return e.JSON(500, map[string]string{"error": err.Error()})
		}

		return e.JSON(200, map[string]any{
			"success": true,
			"message": "인증이 완료되었습니다.",
		})
	}
}
