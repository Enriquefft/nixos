package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"log"
	"net/http"
)

// ============================================================================
// Sentry Webhook Types
// ============================================================================

type SentryEvent struct {
	Culprit   string           `json:"culprit"`
	EventID   string           `json:"event_id"`
	Exception *SentryException `json:"exception"`
	Platform  string           `json:"platform"`
	Request   *SentryRequest   `json:"request"`
	Title     string           `json:"title"`
}

type SentryException struct {
	Values []SentryExceptionValue `json:"values"`
}

type SentryExceptionValue struct {
	Stacktrace *SentryStacktrace `json:"stacktrace"`
	Type       string            `json:"type"`
	Value      string            `json:"value"`
}

type SentryFrame struct {
	ContextLine string `json:"context_line"`
	Filename    string `json:"filename"`
	Function    string `json:"function"`
	Lineno      int    `json:"lineno"`
}

type SentryIssue struct {
	ID        string        `json:"id"`
	Permalink string        `json:"permalink"`
	Project   SentryProject `json:"project"`
	Status    string        `json:"status"`
	Title     string        `json:"title"`
}

type SentryProject struct {
	Slug string `json:"slug"`
}

type SentryRequest struct {
	Method string `json:"method"`
	URL    string `json:"url"`
}

type SentryStacktrace struct {
	Frames []SentryFrame `json:"frames"`
}

type SentryWebhook struct {
	Action string          `json:"action"`
	Data   SentryEventData `json:"data"`
}

type SentryEventData struct {
	Event SentryEvent `json:"event"`
	Issue SentryIssue `json:"issue"`
}

// ============================================================================
// Signature Verification
// ============================================================================

// verifySentrySignature checks the HMAC-SHA256 signature from Sentry.
// Sentry sends raw hex in the sentry-hook-signature header (no "sha256=" prefix).
func verifySentrySignature(body []byte, signature string, secret string) bool {
	if signature == "" {
		return false
	}
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(expected), []byte(signature))
}

// ============================================================================
// Handler
// ============================================================================

func NewSentryHandler(cfg *Config) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "failed to read body", http.StatusBadRequest)
			return
		}

		signature := r.Header.Get("sentry-hook-signature")
		if !verifySentrySignature(body, signature, cfg.Sentry.WebhookSecret) {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			return
		}

		var webhook SentryWebhook
		if err := json.Unmarshal(body, &webhook); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}

		// Only process issue alert triggers — skip everything else
		if webhook.Action != "triggered" {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]bool{"received": true})
			return
		}

		// Fire-and-forget: return 200 immediately, process in background
		go func() {
			if err := analyzeAndCreateIssue(cfg, webhook); err != nil {
				log.Printf("ERROR: sentry triage failed for issue %s: %v", webhook.Data.Issue.ID, err)
			}
		}()

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]bool{"received": true})
	}
}
