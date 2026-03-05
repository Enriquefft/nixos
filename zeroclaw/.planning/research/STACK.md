# Stack Research

**Domain:** Autonomous AI agent configuration infrastructure (NixOS + ZeroClaw)
**Researched:** 2026-03-04
**Confidence:** HIGH (primary sources: live ZeroClaw docs verified Feb 25 2026, existing module.nix, NixOS patterns from codebase)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| NixOS home-manager | 25.11 (nixpkgs) | Renders `config.toml`, installs ZeroClaw, wires systemd user service | Already in use. Declarative deployment is the correct model — config.toml is rendered at build time, not hand-edited. Ensures reproducibility and version control over structural config. |
| `config.lib.file.mkOutOfStoreSymlink` | home-manager builtin | Symlinks live-editable files (docs, skills, cron) without build-time hashing | The only correct way to allow Kiro to self-edit without triggering a NixOS rebuild. Regular `home.file` copies files into the Nix store — symlinks to `/etc/nixos/zeroclaw/` are required for live editing. |
| ZeroClaw daemon mode | Current (Rust binary) | Supervised runtime that runs gateway + channels + cron scheduler as a single process | `zeroclaw daemon` is the correct production entrypoint (not `zeroclaw gateway`). It starts all subsystems together. The current module.nix correctly uses `zeroclaw daemon`. |
| sops-nix | Current | Secret delivery at runtime via `/run/secrets/rendered/zeroclaw.env` | Secrets cannot go in the Nix store (world-readable). sops-nix renders secrets to tmpfs at boot. The `EnvironmentFile` in the systemd unit is the correct injection point. |
| git (via `/etc/nixos` repo) | System git | Version control for all ZeroClaw config | All changes Kiro makes go through git in `/etc/nixos/zeroclaw/`. Git is the audit log, rollback mechanism, and source of truth. Not optional — required for the git-first self-modification model. |
| systemd user services | NixOS builtin | Service lifecycle management for gateway and kapso bridge | User services run as `hybridz` without root. Correct isolation model. `zeroclaw-gateway.service` and `kapso-whatsapp-bridge.service` are already defined correctly. |

### ZeroClaw Config Sections to Configure

This project's `config.toml` is rendered by `module.nix`. These are the sections that matter and how to approach each:

| Section | Status | Priority | What to Configure |
|---------|--------|----------|-------------------|
| `[model_providers.zai]` / `[model_providers.zai-coding]` | Done | — | Wire API must be `chat_completions` (not `openai-responses` — returns 404 on Z.AI) |
| `[identity]` | Partial | High | Currently `format = "openclaw"`. This is the correct format — ZeroClaw's "openclaw" format loads markdown files from `~/.zeroclaw/documents/`. No change needed, but the 6 document symlinks must all be present. |
| `[autonomy]` | Missing | High | Must define `allowed_commands`, `allowed_roots`, `level`, and `auto_approve` list. Without this, Kiro cannot execute shell commands or write files. |
| `[agent]` | Missing | High | Set `max_tool_iterations` (default 20 is low for complex cron tasks), `parallel_tools`, `max_history_messages`. GLM-5 may benefit from `compact_context = false` (it's not a 13B model). |
| `[research]` | Missing | Medium | Enable with `trigger = "keywords"` — lets Kiro research before responding to queries about files, tasks, status. |
| `[memory]` | Missing | Medium | Configure `backend = "sqlite"` (default but explicit is better), `auto_save = true`. No embeddings needed unless semantic search becomes useful later. |
| `[[model_routes]]` | Missing | Medium | Define `hint:fast` (zai/glm-5 for quick tasks) and `hint:reasoning` (zai-coding/glm-5 for code work). Stable hints let cron prompts route correctly without hardcoding model names. |
| `[observability]` | Missing | Medium | Add `runtime_trace_mode = "rolling"` for debugging tool-call failures in cron. Keep `backend = "none"` (no OTLP collector). |
| `[security.estop]` | Missing | Low | Enable for emergency stop capability. `require_otp_to_resume = false` for single-user local setup. |
| `[cost]` | Missing | Low | Enable with `daily_limit_usd = 1.00`, `monthly_limit_usd = 30.00` — matches Enrique's Z.AI $30/month budget. |
| `[skills]` | Missing | Low | `open_skills_enabled = false` (correct default — no community skills). Local skills live in `~/.zeroclaw/skills/` via symlink. |
| `[http_request]` | Missing | Low | Enable with scoped `allowed_domains` for cron jobs that hit APIs (job boards, RSS, etc.). |
| `[channels_config]` | Partial | Done | `cli = true` is set. WhatsApp is handled by kapso bridge externally (correct). |
| `[gateway]` | Done | — | Port 42617, localhost-only, pairing disabled. Correct for single-user local deployment. |
| `[browser]` | Done | — | Enabled with `kiro-browser` path. Correct. |
| `[web_search]` | Done | — | Brave provider. Correct. |

### Symlink Strategy

| Path | Mechanism | Why |
|------|-----------|-----|
| `~/.zeroclaw/documents/*.md` | `mkOutOfStoreSymlink` → `/etc/nixos/zeroclaw/documents/*.md` | Identity docs must be live-editable by Kiro. A rebuild to update SOUL.md would be absurd. Kiro edits → git commit → effective immediately via symlink. |
| `~/.zeroclaw/skills/` | `mkOutOfStoreSymlink` → `/etc/nixos/zeroclaw/skills/` | Skills are created and modified by Kiro at runtime. Nix store would prevent this entirely. |
| `~/.zeroclaw/cron/` (if ZeroClaw uses file-based cron) | `mkOutOfStoreSymlink` → `/etc/nixos/zeroclaw/cron/` | Cron definitions are Kiro-owned. Must be live-editable and version-controlled. Confirm with `zeroclaw config schema` whether cron definitions load from files or only from CLI commands. |
| `~/.zeroclaw/config.toml` | `home.file` with `force = true` (Nix store, rendered at build time) | Structural config (providers, ports, autonomy rules) must go through NixOS. Prevents accidental drift. `force = true` is required because ZeroClaw may create this file on first run. |
| `reference/upstream-docs/` | `mkOutOfStoreSymlink` → `~/Projects/zeroclaw/docs/` | Keeps ZeroClaw docs current via `git pull` in the upstream repo. Any agent working on this infrastructure can read current docs without duplication. |

### Supporting Tools (Already Available System-Wide)

| Tool | Purpose | Notes |
|------|---------|-------|
| `zeroclaw doctor` | Validate config, check provider connectivity | Run after every `module.nix` change. Catches TOML errors before restart. |
| `zeroclaw config schema` | Print JSON Schema for config.toml | Use to verify config options without reading upstream docs. |
| `zeroclaw status` | Print active config summary | Quick sanity check after rebuild. |
| `gpush` | git commit + pull + push | Kiro uses this for self-modification commits. Already available via `scripts.nix`. |
| `journalctl --user -u zeroclaw-gateway -f` | Follow gateway logs | Passwordless via sudo whitelist. Primary debugging tool. |
| `systemctl --user restart zeroclaw-gateway` | Restart gateway after config changes | No sudo needed for user services. |

---

## Installation

This is not a fresh install — ZeroClaw is already installed as a Nix package via `module.nix`. The relevant deployment commands are:

```bash
# After any module.nix or structural config change:
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos

# After any document/skill/cron change (no rebuild needed):
# Changes take effect immediately via symlinks.
# Commit to git:
gpush "docs: update IDENTITY.md"

# Validate config before/after rebuild:
zeroclaw doctor
zeroclaw status

# Restart gateway after config changes that hot-reload:
systemctl --user restart zeroclaw-gateway
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `mkOutOfStoreSymlink` for docs/skills | Regular `home.file` (Nix store copy) | Never for live-editable files. Use `home.file` only for files that are structurally part of the NixOS config and should NOT be editable at runtime (e.g., `config.toml`). |
| `zeroclaw daemon` as systemd entrypoint | `zeroclaw gateway` | Only if you want gateway-only without channels/cron. Wrong for production — use `daemon`. |
| sops-nix rendered env file | Hardcoding secrets in `config.toml` | Never. Nix store is world-readable. sops-nix + `EnvironmentFile` is the only correct pattern on NixOS. |
| `format = "openclaw"` identity | `format = "aieos"` with JSON file | Only if migrating to an AIEOS identity format. Not relevant here — openclaw format (markdown files) is simpler and already working. |
| SQLite memory backend | `lucid` or `markdown` | Use `lucid` only if you need a hosted memory service. Use `markdown` only for human-readable memory that Kiro will manually review. SQLite is the right default: fast, local, no external deps. |
| Z.AI `chat_completions` wire API | `openai-responses` | Never with Z.AI. Returns 404. `chat_completions` is confirmed working. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Ad-hoc cron scripts outside ZeroClaw | Splits cron management across systems, loses version control, breaks the single-source-of-truth model | `zeroclaw cron add` for programmatic cron, or YAML files symlinked via `skills/` for structured job definitions |
| Editing `~/.zeroclaw/` files directly | Violates single-source-of-truth. Changes will be overwritten on next rebuild or aren't version-controlled | Edit in `/etc/nixos/zeroclaw/`, changes propagate via symlinks or rebuild |
| Hardcoding API keys in `config.toml` template | `module.nix` renders to Nix store — world-readable. API keys would be exposed | Use `EnvironmentFile` in systemd unit pointing to sops-rendered secrets |
| `zeroclaw onboard` on an already-configured system | Will overwrite `config.toml` unless `--force` is explicit. Safe refusal exists but adds noise | Only use `onboard` for fresh setups. NixOS manages config declaratively. |
| `open_skills_enabled = true` | Downloads community skills from the internet. Security audit exists but this is an unnecessary attack surface for a private agent | Keep `false`. Install skills locally from `/etc/nixos/zeroclaw/skills/`. |
| Multiple `ZEROCLAW_PROVIDER` env var overrides | Bypasses config.toml provider selection. Creates invisible runtime behavior that doesn't match the declared config | Set `default_provider` in config.toml. Only use env vars for deliberate one-off overrides. |
| `require_pairing = true` on the gateway | Unnecessary for a local-only gateway (bound to 127.0.0.1). Adds friction without security benefit since the gateway is not publicly exposed | Keep `require_pairing = false` for local single-user deployment. |

---

## Stack Patterns by Variant

**For live-editable Kiro behavior (docs, skills, cron):**
- Use `mkOutOfStoreSymlink` to `/etc/nixos/zeroclaw/<path>`
- Edit in source, git commit — effective immediately via symlink
- No rebuild required

**For structural config (providers, ports, autonomy rules, security):**
- Edit `module.nix` TOML template
- Requires `sudo nixos-rebuild switch`
- Run `zeroclaw doctor` after rebuild to validate

**For secrets (API keys, tokens):**
- Add to sops YAML at `/etc/nixos/secrets/zeroclaw.yaml`
- Reference via `EnvironmentFile = [ "/run/secrets/rendered/zeroclaw.env" ]` in systemd unit
- ZeroClaw reads env vars for provider API keys by convention

**For cron job definitions:**
- Use `zeroclaw cron add` CLI for simple jobs
- For complex jobs requiring SKILL.toml manifests, place in `skills/` directory
- Confirm via `zeroclaw cron list` after adding

**For new skills:**
- Create `skills/<name>/SKILL.toml` + implementation in `/etc/nixos/zeroclaw/skills/`
- Symlink propagates to `~/.zeroclaw/skills/` immediately
- No rebuild needed

---

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| ZeroClaw binary | Current (Rust, Feb 2026 docs) | `wire_api = "chat_completions"` required for Z.AI (not `openai-responses`) |
| kapso-whatsapp-plugin | Current | Imported via `inputs.kapso-whatsapp-plugin.homeManagerModules.default` |
| NixOS | 25.11 | home-manager tracks same channel |
| sops-nix | Current | Secrets rendered to `/run/secrets/rendered/zeroclaw.env` |
| GLM-5 via Z.AI | Current | Default model. `default_provider = "zai-coding"`, `default_model = "glm-5"` |

---

## Key Config Sections Not Yet in module.nix

Based on the ZeroClaw config reference (verified Feb 25 2026), these sections are missing from the current `module.nix` and should be added:

```toml
# Autonomy — required for Kiro to use shell and file tools
[autonomy]
level = "supervised"
workspace_only = false
allowed_commands = ["git", "gh", "node", "uv", "python3", "jq", "rg", "fd", "curl", "systemctl", "journalctl", "gpush", "zeroclaw"]
allowed_roots = ["/etc/nixos/zeroclaw", "/home/hybridz/Projects"]
forbidden_paths = ["/etc/nixos/secrets", "/home/hybridz/.ssh", "/home/hybridz/.gnupg"]
auto_approve = ["file_read", "grep", "memory_search"]

# Agent behavior tuning
[agent]
max_tool_iterations = 40
max_history_messages = 50
parallel_tools = true

# Research phase — lets Kiro gather context before responding
[research]
enabled = true
trigger = "keywords"
keywords = ["find", "show", "check", "search", "how many", "what", "list", "status"]
max_iterations = 5

# Memory — explicit config (SQLite is default but should be declared)
[memory]
backend = "sqlite"
auto_save = true

# Observability — rolling runtime trace for debugging cron failures
[observability]
backend = "none"
runtime_trace_mode = "rolling"
runtime_trace_max_entries = 200

# Cost guardrail matching Z.AI $30/month budget
[cost]
enabled = true
daily_limit_usd = 1.00
monthly_limit_usd = 30.00
warn_at_percent = 80

# HTTP requests for cron jobs hitting external APIs
[http_request]
enabled = true
allowed_domains = ["api.linkedin.com", "news.ycombinator.com", "arxiv.org", "github.com"]
timeout_secs = 30
```

---

## Sources

- `/home/hybridz/Projects/zeroclaw/docs/config-reference.md` — Verified Feb 25 2026. PRIMARY source for all config sections, keys, defaults, and notes. HIGH confidence.
- `/home/hybridz/Projects/zeroclaw/docs/commands-reference.md` — Verified Feb 25 2026. CLI surface, `zeroclaw cron`, `zeroclaw skills`, `zeroclaw doctor`. HIGH confidence.
- `/etc/nixos/zeroclaw/module.nix` — Current implementation. Authoritative for what is already configured. HIGH confidence.
- `/etc/nixos/zeroclaw/.planning/PROJECT.md` — Project requirements and constraints. HIGH confidence.
- NixOS home-manager `mkOutOfStoreSymlink` — Standard NixOS pattern for mutable files managed by home-manager. Confirmed in use in existing module.nix. HIGH confidence.
- MEMORY.md note: `Z.AI does NOT support openai-responses API type (returns 404) — use openai-completions` — Session-learned from prior debugging. HIGH confidence (already encoded in module.nix).

---

*Stack research for: ZeroClaw agent configuration infrastructure on NixOS*
*Researched: 2026-03-04*
