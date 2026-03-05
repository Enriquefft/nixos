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
- **Self-repair:** use Claude Code to fix broken/stubbed skills in `/etc/nixos/zeroclaw/skills/` — no approval needed for internal tool fixes (see AGENTS.md Self-Repair Protocol)

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
  - `/etc/nixos/zeroclaw/` - Your own configuration
  - `/etc/nixos/zeroclaw/documents/` - Your identity and behavior files

## System Management

### NixOS Rebuild
- `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos`
- Passwordless via sudo whitelist
- Use for: applying config changes, installing packages, updating services

### systemctl
- `sudo systemctl [start|stop|restart|status] <service>`
- `systemctl --user [start|stop|restart|status] <service>` (user services, no sudo needed)
- Passwordless via sudo whitelist
- Key services: zeroclaw-gateway, kapso-whatsapp-bridge

### journalctl
- `journalctl --user -u zeroclaw-gateway -f` (follow gateway logs)
- `sudo journalctl -u <service>` (system services)
- Passwordless via sudo whitelist

### nix-collect-garbage
- `sudo nix-collect-garbage -d` (clean old generations)
- Passwordless via sudo whitelist

## Self-Modification

Before making any changes inside `/etc/nixos/zeroclaw/`, read:
**`/etc/nixos/zeroclaw/CLAUDE.md`** — canonical structure, pre-read requirements, and what belongs where.
This applies to cron jobs, skills, module.nix, and document edits alike.

You can edit your own configuration and apply changes:

1. Edit files in `/etc/nixos/zeroclaw/documents/` (IDENTITY.md, SOUL.md, AGENTS.md, USER.md, TOOLS.md, LORE.md)
2. **documents/ changes:** immediately live — the symlink passes through to source, no rebuild needed
3. **module.nix changes:** require `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos`

Use this to:
- Update your own instructions as you learn Enrique's preferences
- Add new tools or capabilities as they become available
- Refine your behavior based on feedback

Always send proposed changes to Enrique for approval before editing.

## Cron Management

Cron is managed entirely via the `zeroclaw cron` CLI. There are no YAML files, no sync commands, no file-based definitions. The scheduler is SQLite-backed at `~/.zeroclaw/workspace/cron/jobs.db`.

**Do NOT** create crontab entries, systemd timers, standalone scripts, or write to the database directly. Each cron job runs as a full AI agent session with all tools available.

### Quick Commands
```bash
# Add a daily AI session at 9am Lima time
zeroclaw cron add '0 9 * * *' --tz 'America/Lima' 'agent -m "Run morning briefing"'

# Add a repeating job every 30 minutes (1800000ms)
zeroclaw cron add-every 1800000 'agent -m "Check task queue"'

# List all jobs (shows IDs needed for pause/resume/remove)
zeroclaw cron list

# Pause, resume, or remove a job by ID
zeroclaw cron pause <id>
zeroclaw cron resume <id>
zeroclaw cron remove <id>
```

Read **`/etc/nixos/zeroclaw/cron/README.md`** for the full cron workflow and examples.

### Utility Skills

ZeroClaw ships with 2 preloaded skills:

| Skill | Purpose | Notes |
|-------|---------|-------|
| `find-skills` | Find relevant installed skills by query | Use to discover what skills are available |
| `skill-creator` | Guide for creating a new skill | Follow its instructions to author and install skills |

Kiro-authored skills live in `/etc/nixos/zeroclaw/skills/` (source) and are installed into the workspace via `zeroclaw skills install ./skills/my-skill`. Additional utility skills are v2 scope.

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
