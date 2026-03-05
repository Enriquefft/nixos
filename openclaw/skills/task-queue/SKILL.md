---
name: task-queue
description: Persistent task queue for tracking issues, user tasks, improvements, and followups. Survives context resets.
user-invocable: true
---

## When to Use

- A tool, skill, or API fails during a cron job — file the error as an issue
- The user assigns a task ("today do X", "fix this", "set up Y")
- You discover an improvement opportunity during any session
- A cron job finds something that needs follow-up action
- You need to check what's pending or report queue status

## Usage

```bash
./run.ts add --title "Fix WhatsApp bridge" --type issue --source "morning-briefing" [--description "..."] [--priority 2] [--due-by "2026-03-05"] [--tags infra,whatsapp]
./run.ts list [--status pending] [--type issue] [--limit 10]
./run.ts next
./run.ts update <id> --status in_progress
./run.ts resolve <id> --resolution "Fixed by reconfiguring channel"
./run.ts wontfix <id> --resolution "No longer relevant"
./run.ts stats
./run.ts --help
```

## Options

### add
- `--title <string>` — Short imperative description (required)
- `--type <issue|task|improvement|followup>` — Task type (required)
- `--source <string>` — Who/what created it: "user", "morning-briefing", etc. (required)
- `--description <string>` — Detailed context, error output
- `--priority <1|2|3|4>` — 1=critical, 2=high, 3=normal, 4=low. Auto-assigned by type if omitted.
- `--due-by <ISO 8601>` — Optional deadline
- `--tags <comma-separated>` — Optional tags: infra, api, skill, cron

### list
- `--status <pending|in_progress|blocked>` — Filter by status
- `--type <issue|task|improvement|followup>` — Filter by type
- `--limit <number>` — Max results (default: all)

### next
No options. Returns highest-priority pending task with fewer than 3 attempts.

### update
- Positional: `<id>` — Task UUID
- `--status <pending|in_progress|blocked>` — New status
- `--priority <1|2|3|4>` — New priority
- `--description <string>` — Append/replace description

### resolve / wontfix
- Positional: `<id>` — Task UUID
- `--resolution <string>` — What was done (required)

### stats
No options. Returns queue health metrics.

## Output

JSON to stdout. Examples:

```json
{"action": "added", "task": {"id": "uuid", "title": "...", ...}}
{"action": "duplicate_skipped", "task": {"id": "existing-uuid", ...}}
{"action": "list", "count": 5, "tasks": [...]}
{"action": "next", "task": {...}}
{"action": "next", "task": null, "reason": "queue empty"}
{"action": "stats", "active": {"total": 12, "pending": 8}, ...}
```

## State

`~/.local/state/openclaw-cron/task-queue/tasks.json`

## Priority Rules

| Type | Default Priority | When |
|------|-----------------|------|
| task | 1 (critical) | User-assigned work |
| issue | 2 (high) | Broken infrastructure |
| followup | 3 (normal) | Time-sensitive from cron |
| improvement | 4 (low) | Nice-to-have |
