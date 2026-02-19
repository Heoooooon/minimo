package hooks

import (
	"context"
	"encoding/base64"
	"log"
	"os"
	"sync"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

var (
	fcmClient     *messaging.Client
	fcmClientOnce sync.Once
)

// getFCMClient returns a singleton FCM messaging client.
// Credentials are read from FIREBASE_SERVICE_ACCOUNT_BASE64 env var.
func getFCMClient() *messaging.Client {
	fcmClientOnce.Do(func() {
		ctx := context.Background()

		saBase64 := os.Getenv("FIREBASE_SERVICE_ACCOUNT_BASE64")
		if saBase64 == "" {
			log.Println("[FCM] FIREBASE_SERVICE_ACCOUNT_BASE64 not set, push disabled")
			return
		}

		saJSON, err := base64.StdEncoding.DecodeString(saBase64)
		if err != nil {
			log.Printf("[FCM] Failed to decode service account: %v", err)
			return
		}

		app, err := firebase.NewApp(ctx, nil, option.WithCredentialsJSON(saJSON))
		if err != nil {
			log.Printf("[FCM] Failed to init Firebase app: %v", err)
			return
		}

		client, err := app.Messaging(ctx)
		if err != nil {
			log.Printf("[FCM] Failed to init messaging client: %v", err)
			return
		}

		fcmClient = client
		log.Println("[FCM] Firebase messaging client initialized")
	})

	return fcmClient
}

// sendDirectFCMPush sends a push notification directly via Firebase Admin SDK.
func sendDirectFCMPush(token, title, body string, data map[string]string) error {
	client := getFCMClient()
	if client == nil {
		return nil // push disabled
	}

	msg := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
					Badge: intPtr(1),
				},
			},
		},
		Android: &messaging.AndroidConfig{
			Priority: "high",
			Notification: &messaging.AndroidNotification{
				Sound: "default",
			},
		},
	}

	resp, err := client.Send(context.Background(), msg)
	if err != nil {
		log.Printf("[FCM] Send error: %v", err)
		return err
	}

	log.Printf("[FCM] Sent: %s", resp)
	return nil
}

func intPtr(i int) *int {
	return &i
}
