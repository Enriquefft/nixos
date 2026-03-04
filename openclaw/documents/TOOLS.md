# Tools

## Communication

### WhatsApp (via Kapso Bridge)
- Send messages: `kapso-whatsapp-cli send --to +NUMBER --text "message"`
- Check status: `kapso-whatsapp-cli status`
- Incoming messages arrive as JSON on the gateway WebSocket
- Voice notes are auto-transcribed via local whisper (Spanish)
- **Rule:** Only send to third parties with Enrique's explicit approval

## Web

### Web Search
- Search the web for current information
- Available through Z.AI web search capability
- Use for: job listings, company research, market research, news, trends

### Web Reader
- Fetch and read full web pages
- Available through Z.AI web reader capability
- Use for: reading job descriptions, articles, documentation, competitor analysis

## Code & Development

### Claude Code
- Launch autonomous coding sessions in any project directory
- Primary use: development work on ~/Projects/*
- Enrique has Claude Max, so sessions are available
- Workflow: start session -> monitor -> report results -> create PR if appropriate
- Use for: building features, fixing bugs, creating landing pages, prototyping

### gh CLI (GitHub)
- Full GitHub operations from the command line
- `gh repo`, `gh pr`, `gh issue`, `gh run` (CI status)
- Use for: creating PRs, checking CI, browsing repos, managing issues
- Authenticated as Enriquefft

### Node.js
- Available system-wide
- Run scripts directly: `node script.js`
- npm/npx available

### uv (Python)
- Fast Python package manager and runner
- `uv run script.py`, `uv pip install`
- Use for: quick Python scripts, data processing

## Local AI

### Ollama
- CUDA-accelerated local LLM inference
- Start: `sudo gpu-toggle on` (loads NVIDIA drivers + starts Ollama)
- Stop: `sudo gpu-toggle off`
- Not always running. Start only when needed for local inference tasks.
- Use for: tasks where you want to avoid Z.ai token costs, offline work, experimentation

## File System

- Full read/write/edit access to the filesystem
- Key directories:
  - `~/Projects/` - All project repos (post-shit-now lives here)
  - `/etc/nixos/` - NixOS system configuration
  - `/etc/nixos/openclaw/` - Your own configuration
  - `/etc/nixos/openclaw/documents/` - Your identity and behavior files

## System Management

### NixOS Rebuild
- `sudo nixos-rebuild switch --flake /etc/nixos#nixos` (or just `up`)
- Passwordless via sudo whitelist
- Use for: applying config changes, installing packages, updating services

### systemctl
- `sudo systemctl [start|stop|restart|status] <service>`
- `systemctl --user [start|stop|restart|status] <service>` (user services, no sudo needed)
- Passwordless via sudo whitelist
- Key services: openclaw-gateway, kapso-whatsapp-bridge

### journalctl
- `journalctl --user -u openclaw-gateway -f` (follow gateway logs)
- `sudo journalctl -u <service>` (system services)
- Passwordless via sudo whitelist

### nix-collect-garbage
- `sudo nix-collect-garbage -d` (clean old generations)
- Passwordless via sudo whitelist

## Self-Modification

Before making any changes inside `/etc/nixos/openclaw/`, read:
**`/etc/nixos/openclaw/CLAUDE.md`** — canonical structure, pre-read requirements, and what belongs where.
This applies to cron jobs, skills, module.nix, and document edits alike.

You can edit your own configuration and apply changes:

1. Edit files in `/etc/nixos/openclaw/documents/` (IDENTITY.md, SOUL.md, AGENTS.md, USER.md, TOOLS.md, LORE.md, PROMPTING-EXAMPLES.md)
2. Run `up` to apply
3. Document-only changes don't trigger a Go rebuild, just a symlink update

Use this to:
- Update your own instructions as you learn Enrique's preferences
- Add new tools or capabilities as they become available
- Refine your behavior based on feedback

Always send proposed changes to Enrique for approval before editing.

## Cron Management

Read **`/etc/nixos/openclaw/cron/README.md`** before adding or editing jobs — it is the canonical schema reference.

Cron jobs are file-based and version-controlled under `/etc/nixos/openclaw/cron/`.

### Directory
- `cron/defaults.yaml` — shared defaults (timezone, session)
- `cron/jobs/*.yaml` — one file per scheduled task (source of truth)
- `cron/sync.sh` — syncs YAML definitions to OpenClaw via CLI

### Workflow
- **Add a job:** create a new `.yaml` in `cron/jobs/`, run `cron-sync`
- **Edit a job:** edit the YAML, run `cron-sync`
- **Remove a job:** delete the YAML, run `cron-sync --remove-missing`
- **Preview changes:** `cron-sync --dry-run`
- **Test a job:** `openclaw cron run <id>` (needs env vars loaded)

### Job YAML Schema
```yaml
name: "Job Name"
schedule: "0 8 * * *"
session: main          # or isolated (optional, from defaults)
timezone: "America/Lima"  # optional, from defaults
prompt: |
  Self-contained instructions for the agent session.
```

### Utility Skills
Reusable CLI tools available as OpenClaw skills at `/etc/nixos/openclaw/skills/`:

| Skill | Purpose | Usage |
|-------|---------|-------|
| `job-scanner` | Fetch/filter job board listings | `./run.ts --boards linkedin --remote-only` |
| `rss-reader` | Fetch/parse RSS/Atom feeds | `./run.ts --feeds arxiv,hn --since 24h` |
| `job-tracker` | CRUD on job tracking store | `./run.ts list --status new` |
| `git-activity` | Summarize git commits across ~/Projects/ | `./run.ts --since yesterday` |

All skills follow the CLI contract: JSON stdout, stderr for diagnostics, `--help` for usage, exit 0 on success.
State files: `~/.local/state/openclaw-cron/<skill-name>/`

## Installed CLI Tools

These are available system-wide and may be useful:

- `bat` - Better cat (syntax highlighting)
- `ripgrep` (`rg`) - Fast search
- `fd` - Fast find
- `fzf` - Fuzzy finder
- `jq` - JSON processing
- `ffmpeg` - Media processing
- `whisper-cpp` - Speech-to-text
- `btop` - System monitor
- `eza` - Better ls
- `lazygit` - Git TUI
