---
name: cron-manager
description: Plan, create, edit, remove, list, and test scheduled cron jobs. Each cron job runs as an AI agent session — use the plan→build→create workflow to keep sessions efficient.
user-invocable: false
---

## When to Use

Use this skill for **ANY task that needs to happen on a schedule or repeatedly**:
- Monitoring / tracking (prices, stocks, website changes, uptime)
- Alerts and notifications ("tell me if X happens")
- Periodic scans (job boards, RSS feeds, news)
- Daily/weekly digests and summaries
- Follow-up reminders
- Recurring data collection
- Anything described as "every N minutes/hours/days" or "check regularly"

**Key insight:** Each cron run is a full AI agent session — expensive if done frequently. The `plan` subcommand helps you decide when a backing skill is needed to keep sessions lightweight.

## When NOT to Use

**NEVER do any of these instead of using this skill:**
- Create Python/Node/Bash scripts for monitoring or scheduling
- Use `crontab -e` or create systemd timers
- Write to `~/.openclaw/cron/jobs.json` directly
- Call `openclaw cron add`, `openclaw cron edit`, or `openclaw cron rm` directly
- Create `while sleep` loops or use `watch` for recurring tasks
- Install scheduling libraries (APScheduler, node-cron, etc.)

All of the above bypass version control and the sync system. Use this skill instead.

## Workflow

**ALWAYS start with `plan` — never jump straight to `create`.**

### 1. PLAN — Analyze the task

```bash
./run.ts plan --task "Track BTC price, alert on 5% drop in 1h" --schedule "*/15 * * * *"
```

The plan returns:
- **tier**: `script-only` (skill does everything), `script-agent` (skill gathers data, agent interprets), or `agent-only` (full reasoning needed)
- **costWarning**: alerts if frequency is expensive
- **skillSpec**: what skill to create if one is needed (name, interface, description)
- **suggestedPrompt**: a tools-first prompt template
- **workflow**: step-by-step instructions to follow

### 2. BUILD — Create a backing skill (if plan says so)

If `skillSpec.needed` is true:
```bash
skill-scaffold create --name "<skillSpec.suggestedName>" --description "<skillSpec.description>"
```
Then implement the logic in `skills/<name>/run.ts`:
- Use direct API calls, not web scraping (CoinGecko, RSS feeds, etc.)
- Output structured JSON to stdout
- Follow the CLI contract: `--help`, exit codes, JSON output
- Test it: `./skills/<name>/run.ts --help` and a real invocation

Add the symlink to `module.nix` and rebuild.

### 3. CREATE — Wire it up

```bash
./run.ts create --name "BTC Monitor" --schedule "*/15 * * * *" \
  --requires price-monitor \
  --prompt "Run price-monitor check --asset btc --threshold 5 --window 1h. If alert: false, end silently. If alert: true, send details via WhatsApp."
```

The `--requires` flag validates that referenced skills exist before creating the YAML.

### 4. VERIFY

```bash
./run.ts list
```

## Usage

```bash
./run.ts plan --task "description" --schedule "cron expression"
./run.ts create --name "Job Name" --schedule "0 8 * * *" --prompt "Instructions" [--requires skill1,skill2]
./run.ts edit --name "Job Name" [--schedule "..."] [--prompt "..."] [--session main|isolated]
./run.ts remove --name "Job Name"
./run.ts list [--verbose]
./run.ts test --name "Job Name"
./run.ts --help
```

## Tier Examples

**script-only (monitoring):**
```bash
# Plan identifies: high-frequency + monitoring → script-only, needs price-monitor skill
./run.ts plan --task "Track BTC price, alert on 5% drop" --schedule "*/15 * * * *"
# After building the skill:
./run.ts create --name "BTC Monitor" --schedule "*/15 * * * *" --requires price-monitor \
  --prompt "Run price-monitor check --asset btc --threshold 5 --window 1h. If no alert, end silently. If alert, send via WhatsApp."
```

**script-agent (digest):**
```bash
# Plan identifies: data gathering + digest → script-agent, use existing job-scanner skill
./run.ts plan --task "Scan job boards and send top matches" --schedule "0 8 * * *"
# job-scanner already exists:
./run.ts create --name "Job Scan AM" --schedule "0 8 * * *" --requires job-scanner,job-tracker \
  --prompt "Run job-scanner --new-only. Filter results for roles matching Enrique's profile (see LORE.md). Add top matches via job-tracker add. Draft top-5 digest. Send to Enrique via WhatsApp. Approval required."
```

**agent-only (reasoning):**
```bash
# Plan identifies: reasoning-heavy → agent-only, no skill needed
./run.ts plan --task "Weekly self-audit of performance" --schedule "30 10 * * 0"
./run.ts create --name "Self-Audit" --schedule "30 10 * * 0" \
  --prompt "Weekly Self-Audit. Review your performance for the past week..."
```

## Output

JSON to stdout. Each subcommand returns a structured result:
```json
{ "action": "plan", "tier": "script-only", "skillSpec": { "needed": true, "suggestedName": "price-monitor", ... }, "suggestedPrompt": "...", "workflow": [...] }
{ "action": "created", "name": "BTC Monitor", "file": "btc-monitor.yaml", "requires": ["price-monitor"], "syncResult": "..." }
```

## Internals

This skill manages YAML files in `/etc/nixos/openclaw/cron/jobs/` and runs `cron-sync` to register changes with the gateway. You don't need to understand the internals — just use the CLI commands above.
