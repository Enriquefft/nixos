package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const systemPrompt = `You are a senior software engineer. You have been assigned a bug fix from a Linear issue.

Instructions:
- Read the CLAUDE.md file in the repository root for project-specific rules
- Create a new git branch named fix/linear-<IDENTIFIER> from main
- Analyze the issue description to understand the root cause
- Implement the fix following existing code conventions
- Run the project's lint and typecheck commands if available
- Commit your changes with a message referencing the Linear issue
- Do NOT push the branch — leave it for developer review
- Do NOT create a pull request
- If you cannot determine the fix with confidence, create the branch and commit a TODO comment at the likely location`

func buildUserPrompt(issue LinearIssue) string {
	return fmt.Sprintf(`Fix the following bug reported in Linear issue %s:

Title: %s
URL: %s

Description:
%s

Requirements:
- Create branch fix/linear-%s from main
- Fix the root cause, not just the symptom
- Run lint/typecheck if the project supports it
- Commit with message: "fix: <short description> (linear %s)"`,
		issue.Identifier,
		issue.Title,
		issue.URL,
		issue.Description,
		issue.Identifier,
		issue.Identifier,
	)
}

func triggerClaudeCode(cfg *Config, issue LinearIssue, project ProjectConfig) {
	logDir := filepath.Join(project.Workspace, ".linear-triage")
	if err := os.MkdirAll(logDir, 0o755); err != nil {
		log.Printf("ERROR: failed to create log dir %s: %v", logDir, err)
		return
	}

	timestamp := time.Now().Format("20060102-150405")
	logFile := filepath.Join(logDir, fmt.Sprintf("run-%s-%s.log", issue.ID, timestamp))

	claudeBin := filepath.Join(os.Getenv("HOME"), ".local", "bin", "claude")
	userPrompt := buildUserPrompt(issue)

	cmd := exec.Command(
		"env", "-u", "CLAUDECODE",
		claudeBin,
		"-p",
		"--model", "opus",
		"--effort", "max",
		"--dangerously-skip-permissions",
		"--output-format", "text",
		"--system-prompt", systemPrompt,
		userPrompt,
	)
	cmd.Dir = project.Workspace

	// Filter CLAUDECODE from environment (belt-and-suspenders with env -u)
	env := os.Environ()
	filtered := make([]string, 0, len(env))
	for _, e := range env {
		if !strings.HasPrefix(e, "CLAUDECODE=") {
			filtered = append(filtered, e)
		}
	}
	cmd.Env = filtered

	log.Printf("starting claude for issue %s in %s", issue.Identifier, project.Workspace)

	output, err := cmd.CombinedOutput()
	if writeErr := os.WriteFile(logFile, output, 0o644); writeErr != nil {
		log.Printf("ERROR: failed to write log file %s: %v", logFile, writeErr)
	}

	if err != nil {
		log.Printf("ERROR: claude failed for issue %s: %v", issue.Identifier, err)
		return
	}

	log.Printf("claude completed for issue %s, log: %s", issue.Identifier, logFile)
}
