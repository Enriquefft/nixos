# system-workflows

Purpose-built tools for system-specific workflows. Ensures agents use version-controlled, sync-aware mechanisms instead of ad-hoc scripts.

## Skills

| Skill | Purpose |
|-------|---------|
| `cron-manager` | Create/edit/remove/list/test cron jobs via YAML + `cron-sync` |
| `skill-scaffold` | Scaffold new skills with correct SKILL.md + run.ts structure |

## Hooks

Hook scripts in `scripts/` follow the Claude Code convention (JSON stdin/stdout, exit codes for control). Adapt to OpenClaw's hook API as needed.

| Script | Hook point | Purpose |
|--------|-----------|---------|
| `intent-detector.sh` | Inbound message | Detect scheduling/skill intent → inject workflow context |
| `tool-guard.sh` | PreToolUse (Bash/Write/Edit) | Redirect wrong cron/skill operations → correct tool |

## Extensibility

To add a new protected workflow:
1. Add a skill to `skills/<name>/`
2. Add keywords to `scripts/intent-detector.sh`
3. Add patterns to `scripts/tool-guard.sh`
4. Add a row to the System-First Rule table in `documents/AGENTS.md`
