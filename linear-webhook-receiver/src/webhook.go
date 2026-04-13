package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strings"
	"sync"
)

type LinearIssue struct {
	Description string `json:"description"`
	ID          string `json:"id"`
	Identifier  string `json:"identifier"`
	Title       string `json:"title"`
	URL         string `json:"url"`
}

type LinearWebhookPayload struct {
	Action string      `json:"action"`
	Data   LinearIssue `json:"data"`
	Type   string      `json:"type"`
}

func verifySignature(body []byte, signature string, secret string) bool {
	sig := strings.TrimPrefix(signature, "sha256=")
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(body)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(sig), []byte(expected))
}

func NewWebhookHandler(cfg *Config) http.HandlerFunc {
	var mu sync.Mutex
	inflight := make(map[string]bool)

	return func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "failed to read body", http.StatusBadRequest)
			return
		}

		signature := r.Header.Get("linear-signature")
		if !verifySignature(body, signature, cfg.Linear.WebhookSecret) {
			http.Error(w, "invalid signature", http.StatusUnauthorized)
			return
		}

		var payload LinearWebhookPayload
		if err := json.Unmarshal(body, &payload); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}

		if payload.Action != "create" || payload.Type != "Issue" {
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]bool{"received": true})
			return
		}

		projectID := r.URL.Query().Get("project")
		if projectID == "" {
			http.Error(w, "missing project query parameter", http.StatusBadRequest)
			return
		}

		var project *ProjectConfig
		for i := range cfg.Projects {
			if cfg.Projects[i].ID == projectID {
				project = &cfg.Projects[i]
				break
			}
		}
		if project == nil {
			http.Error(w, "unknown project: "+projectID, http.StatusNotFound)
			return
		}

		issueID := payload.Data.ID
		mu.Lock()
		if inflight[issueID] {
			mu.Unlock()
			log.Printf("issue %s already in-flight, skipping", payload.Data.Identifier)
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode(map[string]bool{"received": true})
			return
		}
		inflight[issueID] = true
		mu.Unlock()

		go func() {
			defer func() {
				mu.Lock()
				delete(inflight, issueID)
				mu.Unlock()
			}()
			triggerClaudeCode(cfg, payload.Data, *project)
		}()

		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]bool{"received": true})
	}
}
