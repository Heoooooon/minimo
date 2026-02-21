package middleware

import (
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
)

// RequireAdmin returns a middleware that checks if the authenticated user
// has the "admin" role. Must be used after RequireAuth().
func RequireAdmin() func(e *core.RequestEvent) error {
	return func(e *core.RequestEvent) error {
		if e.Auth == nil {
			return apis.NewUnauthorizedError("Authentication required", nil)
		}
		if e.Auth.GetString("role") != "admin" {
			return apis.NewForbiddenError("Admin access required", nil)
		}
		return e.Next()
	}
}
