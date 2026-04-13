package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
)

// ============================================================================
// AI Types (OpenAI-compatible)
// ============================================================================

type aiChatMessage struct {
	Content string `json:"content"`
	Role    string `json:"role"`
}

type aiChatRequest struct {
	Messages       []aiChatMessage `json:"messages"`
	Model          string          `json:"model"`
	ResponseFormat aiResponseFmt   `json:"response_format"`
	Temperature    float64         `json:"temperature"`
}

type aiChatResponse struct {
	Choices []aiChoice `json:"choices"`
}

type aiChoice struct {
	Message aiChatMessage `json:"message"`
}

type aiResponseFmt struct {
	Type string `json:"type"`
}

// ============================================================================
// Linear Types
// ============================================================================

type linearCreateInput struct {
	Description string `json:"description"`
	Priority    int    `json:"priority"`
	TeamID      string `json:"teamId"`
	Title       string `json:"title"`
}

type linearGQLRequest struct {
	Query     string                 `json:"query"`
	Variables map[string]interface{} `json:"variables"`
}

type linearIssueData struct {
	ID         string `json:"id"`
	Identifier string `json:"identifier"`
	Title      string `json:"title"`
	URL        string `json:"url"`
}

type linearIssueCreateResult struct {
	Issue   linearIssueData `json:"issue"`
	Success bool            `json:"success"`
}

type linearResponse struct {
	Data struct {
		IssueCreate linearIssueCreateResult `json:"issueCreate"`
	} `json:"data"`
}

// ============================================================================
// Triage Result
// ============================================================================

type TriageResult struct {
	Description string `json:"description"`
	Priority    int    `json:"priority"`
	Title       string `json:"title"`
}

// ============================================================================
// Core Logic
// ============================================================================

func analyzeAndCreateIssue(cfg *Config, webhook SentryWebhook) error {
	// 1. Build prompt from Sentry data
	userPrompt := buildSentryPrompt(webhook)

	// 2. Call Z.AI for analysis
	triage, err := callAI(cfg, userPrompt)
	if err != nil {
		return fmt.Errorf("AI analysis: %w", err)
	}

	// 3. Create Linear issue
	issue, err := createLinearIssue(cfg, triage, webhook.Data.Issue.Permalink)
	if err != nil {
		return fmt.Errorf("Linear issue creation: %w", err)
	}

	log.Printf("created Linear issue %s (%s) for Sentry issue %s: %s",
		issue.Identifier, issue.URL, webhook.Data.Issue.ID, issue.Title)
	return nil
}

// ============================================================================
// Prompt Building
// ============================================================================

const triageSystemPrompt = `You are a senior software engineer triaging production errors. Given a Sentry error, produce a structured analysis as JSON:

{
  "title": "Concise issue title (max 80 chars)",
  "description": "Markdown description with sections: ## Summary, ## Stack Trace, ## Context, ## Suggested Fix",
  "priority": 2
}

Priority scale: 1=urgent (data loss, security), 2=high (feature broken), 3=medium (degraded experience), 4=low (cosmetic, logging).

Be specific about root cause. Reference exact file paths and line numbers from the stack trace. The description should give a developer enough context to start fixing immediately.`

func buildSentryPrompt(webhook SentryWebhook) string {
	event := webhook.Data.Event
	issue := webhook.Data.Issue

	var sb strings.Builder
	fmt.Fprintf(&sb, "Error in project: %s\n", issue.Project.Slug)

	// Exception info
	if event.Exception != nil && len(event.Exception.Values) > 0 {
		v := event.Exception.Values[0]
		fmt.Fprintf(&sb, "Type: %s\n", v.Type)
		fmt.Fprintf(&sb, "Message: %s\n", v.Value)
	}

	fmt.Fprintf(&sb, "Culprit: %s\n", event.Culprit)

	if event.Request != nil {
		fmt.Fprintf(&sb, "URL: %s %s\n", event.Request.URL, event.Request.Method)
	}

	// Stack trace — filter node_modules, take top 8 frames
	sb.WriteString("\nStack trace (most recent frames):\n")
	frames := collectFrames(event)
	if len(frames) == 0 {
		sb.WriteString("  No application stack frames available.\n")
	} else {
		for _, f := range frames {
			fmt.Fprintf(&sb, "  %s:%d in %s\n", f.Filename, f.Lineno, f.Function)
			if f.ContextLine != "" {
				fmt.Fprintf(&sb, "    %s\n", f.ContextLine)
			}
		}
	}

	fmt.Fprintf(&sb, "\nSentry link: %s\n", issue.Permalink)
	return sb.String()
}

func collectFrames(event SentryEvent) []SentryFrame {
	if event.Exception == nil {
		return nil
	}

	var all []SentryFrame
	for _, v := range event.Exception.Values {
		if v.Stacktrace == nil {
			continue
		}
		for _, f := range v.Stacktrace.Frames {
			if strings.Contains(f.Filename, "node_modules") {
				continue
			}
			all = append(all, f)
		}
	}

	// Take last 8 frames (most recent)
	if len(all) > 8 {
		all = all[len(all)-8:]
	}
	return all
}

// ============================================================================
// Z.AI Call
// ============================================================================

func callAI(cfg *Config, userPrompt string) (*TriageResult, error) {
	reqBody := aiChatRequest{
		Messages: []aiChatMessage{
			{Content: triageSystemPrompt, Role: "system"},
			{Content: userPrompt, Role: "user"},
		},
		Model:          cfg.AI.Model,
		ResponseFormat: aiResponseFmt{Type: "json_object"},
		Temperature:    0.3,
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	url := strings.TrimRight(cfg.AI.BaseURL, "/") + "/chat/completions"
	req, err := http.NewRequest("POST", url, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+cfg.AI.APIKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("AI API returned %d: %s", resp.StatusCode, string(respBody))
	}

	var chatResp aiChatResponse
	if err := json.Unmarshal(respBody, &chatResp); err != nil {
		return nil, fmt.Errorf("parse AI response: %w", err)
	}

	if len(chatResp.Choices) == 0 {
		return nil, fmt.Errorf("AI returned no choices")
	}

	content := chatResp.Choices[0].Message.Content
	var triage TriageResult
	if err := json.Unmarshal([]byte(content), &triage); err != nil {
		return nil, fmt.Errorf("parse triage JSON: %w (content: %s)", err, content)
	}

	return &triage, nil
}

// ============================================================================
// Linear Issue Creation
// ============================================================================

const linearCreateMutation = `mutation IssueCreate($input: IssueCreateInput!) {
  issueCreate(input: $input) {
    success
    issue {
      id
      url
      identifier
      title
    }
  }
}`

func createLinearIssue(cfg *Config, triage *TriageResult, sentryPermalink string) (*linearIssueData, error) {
	sentryLink := fmt.Sprintf("\n\n---\n[View in Sentry](%s)", sentryPermalink)
	description := triage.Description + sentryLink

	gqlReq := linearGQLRequest{
		Query: linearCreateMutation,
		Variables: map[string]interface{}{
			"input": linearCreateInput{
				Description: description,
				Priority:    triage.Priority,
				TeamID:      cfg.Linear.TeamID,
				Title:       triage.Title,
			},
		},
	}

	bodyBytes, err := json.Marshal(gqlReq)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", "https://api.linear.app/graphql", bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}
	// Linear API key: NO "Bearer" prefix
	req.Header.Set("Authorization", cfg.Linear.APIKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Linear API returned %d: %s", resp.StatusCode, string(respBody))
	}

	var linearResp linearResponse
	if err := json.Unmarshal(respBody, &linearResp); err != nil {
		return nil, fmt.Errorf("parse Linear response: %w", err)
	}

	if !linearResp.Data.IssueCreate.Success {
		return nil, fmt.Errorf("Linear issueCreate returned success: false")
	}

	return &linearResp.Data.IssueCreate.Issue, nil
}
