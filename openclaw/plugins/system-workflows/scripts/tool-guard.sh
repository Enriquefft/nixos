#!/usr/bin/env bash
# tool-guard.sh — PreToolUse hook
#
# Claude Code hooks-inspired: reads tool call on stdin (JSON),
# checks if it bypasses a protected workflow (cron, skill),
# and either allows or denies with a redirect message.
#
# API contract (Claude Code shape — adapt for OpenClaw):
#   stdin:  { "tool_name": "Bash", "tool_input": { "command": "..." } }
#           or { "tool_name": "Write", "tool_input": { "file_path": "...", "content": "..." } }
#           or { "tool_name": "Edit", "tool_input": { "file_path": "...", ... } }
#   stdout: { "decision": "allow" } or { "decision": "deny", "reason": "..." }
#   exit 0: allow
#   exit 2: deny (tool call is blocked, reason shown to agent)

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")

if [ -z "$TOOL_NAME" ]; then
  echo '{"decision": "allow"}'
  exit 0
fi

# --- Extract relevant fields ---
case "$TOOL_NAME" in
  Bash|bash)
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
    CHECK_TARGET="$COMMAND"
    ;;
  Write|write|Edit|edit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_str // empty' 2>/dev/null || echo "")
    CHECK_TARGET="$FILE_PATH $CONTENT"
    ;;
  *)
    echo '{"decision": "allow"}'
    exit 0
    ;;
esac

# --- Whitelist: cron-sync itself and cron-manager skill ---
if echo "$CHECK_TARGET" | grep -qE 'cron-sync|cron-manager/run\.ts'; then
  echo '{"decision": "allow"}'
  exit 0
fi

deny() {
  local reason="$1"
  jq -n --arg r "$reason" '{"decision": "deny", "reason": $r}'
  exit 2
}

# --- Cron workflow violations ---

# Direct writes to jobs.json
if echo "$CHECK_TARGET" | grep -qE '\.openclaw/cron/jobs\.json|openclaw.*cron.*jobs\.json'; then
  deny "Do not write to jobs.json directly. Use cron-manager: ./skills/cron-manager/run.ts create --name '<name>' --schedule '<cron>' --prompt '<instructions>'. jobs.json is managed by cron-sync."
fi

# Direct openclaw cron add/edit/rm (bypasses YAML source of truth)
if echo "$CHECK_TARGET" | grep -qE 'openclaw\s+cron\s+(add|edit|rm|remove|delete)'; then
  deny "Do not use 'openclaw cron add/edit/rm' directly. Use cron-manager: ./skills/cron-manager/run.ts create|edit|remove. This ensures jobs stay in version-controlled YAML."
fi

# crontab or systemd timer creation
if echo "$CHECK_TARGET" | grep -qE 'crontab\s+-e|crontab\s+-l.*>>|systemctl.*enable.*timer|\.timer.*\[Timer\]'; then
  deny "Do not create crontab entries or systemd timers for scheduled tasks. Use cron-manager: ./skills/cron-manager/run.ts create. OpenClaw cron jobs run as full agent sessions with all tools."
fi

# Python/Node scheduling libraries
if echo "$CHECK_TARGET" | grep -qE 'import\s+schedule|from\s+apscheduler|setInterval.*\d{4,}|while.*sleep.*\d'; then
  deny "Do not create standalone scheduling scripts. Use cron-manager: ./skills/cron-manager/run.ts create. OpenClaw cron jobs are agent sessions that can reason, adapt, and use all tools."
fi

# --- Task queue violations ---

# Direct writes to task-queue state
if echo "$CHECK_TARGET" | grep -qE 'openclaw-cron/task-queue/tasks\.json'; then
  deny "Do not write to tasks.json directly. Use the task-queue skill: task-queue add --title '...' --type issue --source '...'"
fi

# --- Skill workflow violations ---

# Creating skill files outside the skills directory
if echo "$CHECK_TARGET" | grep -qE 'SKILL\.md' && ! echo "$CHECK_TARGET" | grep -qE '/etc/nixos/openclaw/(skills|plugins)/'; then
  deny "SKILL.md files should only be created in /etc/nixos/openclaw/skills/. Use skill-scaffold: ./skills/skill-scaffold/run.ts create --name '<name>' --description '<desc>'."
fi

# --- Allow everything else ---
echo '{"decision": "allow"}'
exit 0
