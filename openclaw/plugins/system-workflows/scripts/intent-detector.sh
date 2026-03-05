#!/usr/bin/env bash
# intent-detector.sh — Inbound message hook
#
# Claude Code hooks-inspired: reads user message on stdin (JSON),
# detects scheduling or skill-creation intent via keyword matching,
# and returns additionalContext to guide the agent toward the correct workflow.
#
# API contract (Claude Code shape — adapt for OpenClaw):
#   stdin:  { "message": "user's message text" }
#   stdout: { "additionalContext": "..." }  (empty string if no match)
#   exit 0: continue with optional context
#   exit 2: block (not used here — we inject context, not block)

set -euo pipefail

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // empty' 2>/dev/null || echo "")

if [ -z "$MESSAGE" ]; then
  echo '{"additionalContext": ""}'
  exit 0
fi

# Lowercase for matching
MSG_LOWER=$(echo "$MESSAGE" | tr '[:upper:]' '[:lower:]')

# --- Scheduling intent detection ---
SCHEDULING_KEYWORDS=(
  "every .* hour"
  "every .* minute"
  "every .* day"
  "every morning"
  "every night"
  "daily"
  "weekly"
  "hourly"
  "monitor"
  "track"
  "tracking"
  "alert me"
  "alert when"
  "alert if"
  "notify me"
  "notify when"
  "notify if"
  "recurring"
  "scheduled"
  "schedule"
  "periodic"
  "periodically"
  "check every"
  "check periodically"
  "price watch"
  "price alert"
  "price drop"
  "cron job"
  "cron task"
  "run automatically"
  "run on a schedule"
  "keep checking"
  "watch for"
)

SCHEDULING_MATCH=false
for pattern in "${SCHEDULING_KEYWORDS[@]}"; do
  if echo "$MSG_LOWER" | grep -qE "$pattern"; then
    SCHEDULING_MATCH=true
    break
  fi
done

# --- Skill creation intent detection ---
SKILL_KEYWORDS=(
  "create a tool"
  "create a skill"
  "new skill"
  "new tool"
  "build a tool"
  "build a skill"
  "reusable automation"
  "reusable script"
  "reusable tool"
  "automate this"
  "keep doing this manually"
  "i always have to"
  "scaffold a"
)

SKILL_MATCH=false
for pattern in "${SKILL_KEYWORDS[@]}"; do
  if echo "$MSG_LOWER" | grep -qE "$pattern"; then
    SKILL_MATCH=true
    break
  fi
done

# --- Task assignment intent detection ---
TASK_KEYWORDS=(
  "today do"
  "today set up"
  "today fix"
  "today work on"
  "add to queue"
  "queue this"
  "remember to"
  "todo:"
  "task:"
  "fix this"
  "when you get a chance"
  "don't forget"
  "no te olvides"
  "hoy haz"
  "hoy configura"
  "hoy arregla"
)

TASK_MATCH=false
for pattern in "${TASK_KEYWORDS[@]}"; do
  if echo "$MSG_LOWER" | grep -qE "$pattern"; then
    TASK_MATCH=true
    break
  fi
done

# --- Build context ---
CONTEXT=""

if [ "$SCHEDULING_MATCH" = true ]; then
  CONTEXT+="⚡ SCHEDULING WORKFLOW — Follow these steps in order:"
  CONTEXT+=$'\n'
  CONTEXT+="1. PLAN: Run \`cron-manager plan --task '<summarize the user request>' --schedule '<estimate cron expression>'\`"
  CONTEXT+=$'\n'
  CONTEXT+="2. Read the plan output. It tells you the tier (script-only, script-agent, agent-only), whether a backing skill is needed, and suggests a prompt."
  CONTEXT+=$'\n'
  CONTEXT+="3. BUILD (if plan says skillSpec.needed=true): Create the skill with \`skill-scaffold create\`, implement the logic in run.ts, test it."
  CONTEXT+=$'\n'
  CONTEXT+="4. CREATE: Run \`cron-manager create --name '...' --schedule '...' --prompt '...' [--requires <skill>]\` using the plan's suggestedPrompt as a starting point."
  CONTEXT+=$'\n'
  CONTEXT+="5. VERIFY: Run \`cron-manager list\` to confirm."
  CONTEXT+=$'\n'
  CONTEXT+="IMPORTANT: Do NOT skip the plan step. Do NOT create agent-only prompts for tasks that should use skills. Read the cron-manager SKILL.md if you need more details."
fi

if [ "$SKILL_MATCH" = true ]; then
  if [ -n "$CONTEXT" ]; then
    CONTEXT+=$'\n\n'
  fi
  CONTEXT+="⚡ SYSTEM WORKFLOW: This looks like a skill/tool creation task. "
  CONTEXT+="Use the skill-scaffold skill: ./run.ts create --name '<name>' --description '<desc>'. "
  CONTEXT+="Do NOT create scripts in random directories. "
  CONTEXT+="Skills live in /etc/nixos/openclaw/skills/<name>/ with SKILL.md + run.ts. "
  CONTEXT+="Read skill-scaffold SKILL.md or skills/README.md if you need more details."
fi

if [ "$TASK_MATCH" = true ]; then
  if [ -n "$CONTEXT" ]; then
    CONTEXT+=$'\n\n'
  fi
  CONTEXT+="⚡ TASK CAPTURE — The user is assigning a task. Before executing:"
  CONTEXT+=$'\n'
  CONTEXT+="1. Add it to the queue: \`task-queue add --title \"<summarize>\" --type task --source \"user\" --priority 1\`"
  CONTEXT+=$'\n'
  CONTEXT+="2. Confirm to the user: \"Queued. Working on it now.\" (or \"Queued for next worker cycle.\")"
  CONTEXT+=$'\n'
  CONTEXT+="3. If the task sounds urgent or simple, attempt it immediately AND keep it queued as a record."
  CONTEXT+=$'\n'
  CONTEXT+="4. If completed, run \`task-queue resolve <id> --resolution \"...\"\`."
fi

# Output
jq -n --arg ctx "$CONTEXT" '{"additionalContext": $ctx}'
