# Cron — Operational Guide

This guide covers everything needed to schedule, manage, and remove cron jobs in ZeroClaw. The cron system is SQLite-backed and managed entirely via the `zeroclaw cron` CLI — there are no YAML files, no cron-sync command, and no configuration files to edit.

---

## Overview

ZeroClaw's scheduler stores all jobs in a SQLite database at:

```
~/.zeroclaw/workspace/cron/jobs.db
```

**Key properties:**

- `cron.enabled` defaults to `true` — no configuration change needed to use cron
- All job management is done via `zeroclaw cron` CLI commands
- Job IDs are assigned by SQLite and retrieved via `zeroclaw cron list`
- Cron commands can be shell commands or `agent -m "prompt"` for AI-driven sessions
- Jobs persist across restarts — stored in SQLite, not in memory

**Cron commands run as full shell commands.** For AI-driven sessions, use `agent -m "your prompt here"` as the command. For shell automation, use a full shell path or a command that is on PATH.

---

## Schedule Expressions

Standard 5-field cron syntax:

```
* * * * *
│ │ │ │ │
│ │ │ │ └── Weekday (0-6, Sunday=0)
│ │ │ └──── Month (1-12)
│ │ └────── Day of month (1-31)
│ └──────── Hour (0-23)
└────────── Minute (0-59)
```

### Common Examples

| Expression | Meaning |
|------------|---------|
| `0 9 * * *` | Every day at 9:00 AM |
| `0 * * * *` | Every hour on the hour |
| `*/30 * * * *` | Every 30 minutes |
| `0 9 * * 1-5` | Weekdays only at 9:00 AM |
| `0 9 * * 1` | Every Monday at 9:00 AM |
| `0 0 1 * *` | First day of every month at midnight |

### Timezone

Use the `--tz` flag with an IANA timezone name to schedule jobs in a local timezone:

```bash
zeroclaw cron add '0 9 * * *' --tz 'America/Lima' 'agent -m "Run morning briefing"'
```

Without `--tz`, jobs run in the system timezone.

---

## CLI Reference

| Command | Parameters | Description |
|---------|-----------|-------------|
| `zeroclaw cron list` | — | List all scheduled jobs with IDs, expressions, and commands |
| `zeroclaw cron add '<expr>' [--tz <TZ>] '<command>'` | expr: cron expression, TZ: IANA timezone | Add a recurring job on a cron schedule |
| `zeroclaw cron add-every <ms> '<command>'` | ms: interval in milliseconds | Add a job that repeats every N milliseconds |
| `zeroclaw cron add-at '<rfc3339>' '<command>'` | rfc3339: ISO 8601 timestamp | Add a one-time job at a specific timestamp |
| `zeroclaw cron once <delay> '<command>'` | delay: delay before first run | Run once after a delay |
| `zeroclaw cron pause <id>` | id: job ID from cron list | Pause a job without removing it |
| `zeroclaw cron resume <id>` | id: job ID from cron list | Resume a paused job |
| `zeroclaw cron remove <id>` | id: job ID from cron list | Permanently remove a job |

**Getting job IDs:** Always use `zeroclaw cron list` to get the current ID for pause/resume/remove. IDs are integers assigned by SQLite.

---

## Workflow Examples

### Example 1: Daily AI session at 9am Lima time

```bash
# Add the job
zeroclaw cron add '0 9 * * *' --tz 'America/Lima' 'agent -m "Run morning briefing"'

# Confirm it was added
zeroclaw cron list

# To remove later (use the ID from cron list)
zeroclaw cron remove <id>
```

### Example 2: Every 30 minutes task check

```bash
# 30 minutes = 1,800,000 milliseconds
zeroclaw cron add-every 1800000 'agent -m "Check task queue and process pending items"'

# List to see the job ID
zeroclaw cron list

# Pause without removing (e.g., during maintenance)
zeroclaw cron pause <id>

# Resume when ready
zeroclaw cron resume <id>
```

### Example 3: One-time scheduled job at a specific timestamp

```bash
# Schedule a one-time follow-up (RFC 3339 timestamp with timezone offset)
zeroclaw cron add-at '2026-03-05T09:00:00-05:00' 'agent -m "Follow up on application to Stripe"'

# Confirm the job is queued
zeroclaw cron list
```

### Example 4: Shell automation (non-AI cron)

```bash
# Run a shell script on a cron schedule
zeroclaw cron add '0 2 * * *' '/run/current-system/sw/bin/bash -c "cd /etc/nixos && git pull --rebase"'
```

For shell commands not invoked via `agent -m`, use the full absolute path to the binary to ensure the correct version runs regardless of the user's PATH at execution time.

---

## Conventions

### Naming Cron Commands

Write descriptive command strings — they appear in `zeroclaw cron list` and serve as the job's human-readable label.

For AI sessions:
```bash
'agent -m "Run morning briefing — job scan, task triage, overnight summary"'
```

For shell commands:
```bash
'/run/current-system/sw/bin/bash -c "backup-database.sh"'
```

### Managing Job IDs

Job IDs are assigned by SQLite and are not predictable. Always:

1. Run `zeroclaw cron list` first to get the current ID
2. Then run `zeroclaw cron pause <id>`, `resume <id>`, or `remove <id>`

There is no "get job by name" command — use the list to find IDs.

### No Files to Commit

Cron jobs are managed via CLI and stored in SQLite — there are no files to add to git after creating a cron job. Document recurring jobs in a skill or in comments when relevant.

---

## Database Schema (Power Users)

The SQLite database at `~/.zeroclaw/workspace/cron/jobs.db` contains:

**`cron_jobs` table — primary job store:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Auto-assigned job ID (use in pause/resume/remove) |
| `expression` | TEXT | Cron expression (e.g., `0 9 * * *`) or interval |
| `command` | TEXT | Shell command to execute |
| `name` | TEXT | Optional job label |
| `job_type` | TEXT | `cron`, `interval`, `once`, or `at` |
| `schedule` | TEXT | Human-readable schedule description |

**`cron_runs` table — execution history:**

Tracks up to 50 runs per job by default (`max_run_history = 50`). Includes timestamps and exit status.

Do not write to `jobs.db` directly. Only use `zeroclaw cron` CLI.

---

## Anti-Patterns

Do NOT use any of the following — they are OpenClaw patterns that do not exist in ZeroClaw:

| Anti-Pattern | Why Wrong | Correct Approach |
|-------------|-----------|-----------------|
| Creating YAML files in `cron/` | No file-based cron in ZeroClaw | Use `zeroclaw cron add` CLI only |
| Running `cron-sync` | Does not exist in ZeroClaw | No sync needed — SQLite is the source |
| Running `cron-manager` | Does not exist in ZeroClaw | Use `zeroclaw cron` subcommands |
| Writing to `jobs.db` directly | Bypasses ZeroClaw internals | Only use `zeroclaw cron` CLI |
| Using systemd timers for AI sessions | Cannot run agent sessions | `zeroclaw cron add` supports `agent -m "prompt"` natively |
