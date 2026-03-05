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
- Available through Brave Search API
- Use for: job listings, company research, market research, news, trends

### Web Reader
- Fetch and read full web pages
- Available through Brave Search API
- Use for: reading job descriptions, articles, documentation, competitor analysis

## Code & Development

### Claude Code
- Launch autonomous coding sessions in any project directory
- Primary use: development work on ~/Projects/*
- Enrique has Claude Max, so sessions are available
- Workflow: start session -> monitor -> report results -> create PR if appropriate
- Use for: building features, fixing bugs, creating landing pages, prototyping
- **Self-repair:** use Claude Code to fix broken/stubbed skills in `/etc/nixos/openclaw/skills/` — no approval needed for internal tool fixes (see AGENTS.md Self-Repair Protocol)

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
- `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos`
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

**Preferred interface: `cron-manager` skill** — handles YAML creation, validation, and sync in one step.

Read **`/etc/nixos/openclaw/cron/README.md`** for the full schema reference.

Cron jobs are file-based and version-controlled under `/etc/nixos/openclaw/cron/`.

### Quick Commands (via cron-manager)
- **Add a job:** `./skills/cron-manager/run.ts create --name "Name" --schedule "0 8 * * *" --prompt "Instructions"`
- **Edit a job:** `./skills/cron-manager/run.ts edit --name "Name" --schedule "*/30 * * * *"`
- **Remove a job:** `./skills/cron-manager/run.ts remove --name "Name"`
- **List jobs:** `./skills/cron-manager/run.ts list`
- **Test a job:** `./skills/cron-manager/run.ts test --name "Name"`
- **Preview sync:** `cron-sync --dry-run`

**Do NOT** create standalone Python/bash scripts, crontab entries, systemd timers, or write to `jobs.json` directly. Each cron job runs as a full AI agent session with all tools.

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
| `cron-manager` | Create, edit, remove, list, test cron jobs | `./run.ts create --name "Name" --schedule "0 8 * * *" --prompt "..."` |
| `skill-scaffold` | Scaffold new skills with SKILL.md + run.ts | `./run.ts create --name "my-tool" --description "..."` |
| `job-scanner` | Fetch/filter job board listings | `./run.ts --boards linkedin --remote-only` |
| `rss-reader` | Fetch/parse RSS/Atom feeds | `./run.ts --feeds arxiv,hn --since 24h` |
| `job-tracker` | CRUD on job tracking store | `./run.ts list --status new` |
| `git-activity` | Summarize git commits across ~/Projects/ | `./run.ts --since yesterday` |
| `task-queue` | Persistent task queue for issues, tasks, improvements | `./run.ts add --title "..." --type issue --source "cron-name"` |

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
