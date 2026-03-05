# OpenClaw Agent Configuration

Personal OpenClaw agent configuration sub-flake.

## Structure

| Path | Purpose | Pre-read |
|------|---------|----------|
| `module.nix` | Gateway config, model providers (ZAI, ZAI-Coding), agent defaults, bundled plugins, skill symlinks | This file |
| `documents/` | **OpenClaw agent identity** (Kiro's brain) — NOT repo docs. Editing these changes how Kiro thinks and acts. | [`AGENTS.md`](documents/AGENTS.md), [`IDENTITY.md`](documents/IDENTITY.md) |
| `skills/` | Bun/TS CLI tools as OpenClaw skills. Live edits, no rebuild. | [`skills/README.md`](skills/README.md) |
| `cron/` | YAML job definitions synced via `cron-sync`. No rebuild needed. | [`cron/README.md`](cron/README.md) |
| `plugins/` | Custom plugin code. `system-workflows` provides cron-manager + skill-scaffold skills and hook infrastructure. Two bundled plugins also enabled in `module.nix`: `summarize`, `gogcli`. | [`plugins/system-workflows/README.md`](plugins/system-workflows/README.md) |
| `reference/` | Reusable content: full profile (`full-profile.md`), application response templates (`reusable-responses.md`) | — |
| `flake.nix` | Sub-flake inputs (nixpkgs, nix-openclaw, kapso-whatsapp-plugin) | — |

### documents/ files

This are files to be used by Openclaw during runtime.

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Who Kiro is (chief of staff, 24/7, WhatsApp) |
| `SOUL.md` | Personality, communication style, system access rules |
| `AGENTS.md` | Operational directives, approval gates, priority stack |
| `TOOLS.md` | Available tools and capabilities inventory |
| `USER.md` | Enrique's profile summary |
| `LORE.md` | Strategy, job search, distribution, research context |
| `PROMPTING-EXAMPLES.md` | Behavior pattern examples |

## Extension Architecture

We customize OpenClaw **without forking** — extend via plugins, skills, config, and identity documents.

### Plugin capabilities

Plugins run in-process and can:
- Intercept/modify tool calls (`before_tool_call`, `after_tool_call`)
- Intercept messages (inbound before LLM, outbound before delivery)
- Register tools, CLI commands, services, HTTP endpoints, skills

Plugins CANNOT: modify system prompt, add/remove tools mid-session, modify tool call results, override core auth.

**Principle:** Build on OpenClaw — use plugins, skills, and config. Don't bypass internals.

## Skills

See [`skills/README.md`](skills/README.md) for CLI contract and inventory.

- Skills with `package.json` need `bun install` in their directory
- Per-skill `config.json` files are runtime config (not committed)
- The `whatsapp` skill is symlinked from `~/Projects/openclaw-kapso-whatsapp/skills/whatsapp` (external repo)
- `task-queue` is the canonical system for tracking issues, user tasks, improvements, and followups. See AGENTS.md "Task Queue Protocol" for filing rules.

### Plugin-provided skills

The `system-workflows` plugin provides two additional skills (symlinked from `plugins/system-workflows/skills/`):

| Skill | Purpose | Usage |
|-------|---------|-------|
| `cron-manager` | Create, edit, remove, list, test cron jobs via YAML + cron-sync | `./run.ts create --name "Name" --schedule "0 8 * * *" --prompt "..."` |
| `skill-scaffold` | Scaffold new skills with correct SKILL.md + run.ts structure | `./run.ts create --name "my-tool" --description "..."` |

## Cron

YAML jobs synced via `cron-sync`. Quick reference: `cron-sync --dry-run` to preview, `cron-sync` to apply.

See [`cron/README.md`](cron/README.md) for schema and workflow.

## Secrets

Injected at runtime from `/run/secrets/rendered/openclaw.env` (managed by `modules/services/openclaw-secrets.nix`).

| Variable | Purpose |
|----------|---------|
| `OPENCLAW_TOKEN` | Gateway auth token |
| `ZAI_API_KEY` | Z.AI API key |
| `KAPSO_API_KEY` | Kapso API key |
| `KAPSO_PHONE_NUMBER_ID` | WhatsApp phone number ID |
| `GOG_KEYRING_PASSWORD` | GOG keyring |
| `BRAVE_API_KEY` | Brave web search |

## Testing

```bash
nix flake check                                                                  # syntax validation
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos     # full rebuild
systemctl --user status openclaw-gateway kapso-whatsapp-bridge                   # check services
cron-sync --dry-run                                                              # preview cron changes
```

Document-only changes (`documents/`) only trigger a symlink update on rebuild, not a Go rebuild.

## Maintenance

When you modify this sub-flake's structure (add/remove skills, change module.nix schema, update cron workflow), update this CLAUDE.md. This file is the single source of truth for coding agents.

Do NOT duplicate stable information into memory files — if it's true across sessions, it belongs here.
