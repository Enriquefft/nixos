# Cron System

Cron jobs are defined as YAML files, version-controlled in git, and synced to OpenClaw's
runtime scheduler via `cron-sync`. No nix rebuild needed for job changes.

## Directory Layout

```
cron/
├── defaults.yaml          # shared defaults (timezone: America/Lima, session: main)
├── sync.sh                # syncs YAML → OpenClaw CLI (source of truth for cron-sync command)
└── jobs/                  # one YAML per scheduled task
    ├── morning-briefing.yaml
    ├── job-scan-am.yaml
    └── ...                # 12 total
```

## Job YAML Schema

```yaml
name: "Job Name"           # identity key (matched by name during sync)
schedule: "0 8 * * *"      # cron expression
session: main              # main (uses --system-event) or isolated (uses --message)
timezone: "America/Lima"   # optional, inherits from defaults.yaml
prompt: |
  Self-contained instructions for this agent session.
```

## Workflow

```bash
# Preview changes
cron-sync --dry-run

# Apply changes (add/edit YAML, then sync)
cron-sync

# Remove jobs (delete YAML, then sync with flag)
cron-sync --remove-missing

# Test a specific job manually
export $(cat /run/secrets/rendered/openclaw.env | xargs)
openclaw cron run <job-id>
```

## How sync.sh works

1. Loads env vars from `/run/secrets/rendered/openclaw.env`
2. Reads `defaults.yaml` for shared config
3. Reads all `jobs/*.yaml`, merges with defaults
4. Reads current job IDs from `~/.openclaw/cron/jobs.json` (read-only)
5. Matches by name: existing → `openclaw cron edit`, new → `openclaw cron add`
6. All mutations go through OpenClaw's native CLI, not direct file writes

## CLI constraints

- `--session main` requires `--system-event "prompt"` (systemEvent payload)
- `--session isolated` requires `--message "prompt"` (agentTurn payload)
- CLI needs env vars loaded: `export $(cat /run/secrets/rendered/openclaw.env | xargs)`

## Design principles

- **Build on OpenClaw** — use native CLI and skills, don't bypass internals
- **LLM-first** — every cron is an agent session with a self-contained prompt
- **Scripts are tools, not infrastructure** — utility skills the agent uses with full liberty
- **Version controlled** — all definitions in git under `/etc/nixos/openclaw/`
