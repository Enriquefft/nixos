# Phase 1: Config Foundation - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the complete config.toml (autonomy, memory, observability, agent, agents_ipc sections) and complete the module.nix deployment model (skills/, cron/ symlinks, reference/upstream-docs symlink). The gateway must pass zero-warning `zeroclaw doctor` after a clean rebuild. Identity documents, scaffolding READMEs, and behavioral docs are Phase 2+3.

</domain>

<decisions>
## Implementation Decisions

### Autonomy level
- `level = "supervised"` — medium-risk commands (shell, file writes) require approval; safe default for a personal agent with shell access
- `workspace_only = false` — Kiro must operate outside workspace (git in /etc/nixos/zeroclaw, nix builds, Projects/)
- `allowed_roots = ["/etc/nixos/", "~/Projects/"]` — minimum viable access as specified in CFG-01; can be expanded later
- `allowed_commands` allowlist: git, nix, nixos-rebuild, nixos-rebuild, systemctl, journalctl, zeroclaw, gpush, gcommit, gh, cargo, node, bun, npm, python3, bash, sh, ls, cat, grep, find, cp, mv, rm, mkdir, chmod, chown, curl, wget, jq, direnv, sudo (for approved operations)

### Agent limits
- `max_tool_iterations = 40` — default (20) is too low for long git + nix operations; 40 gives headroom for complex autonomous tasks
- `max_history_messages = 100` — Kiro operates as a chief of staff across long sessions; 50 default is insufficient for cross-context reasoning

### Memory
- `backend = "sqlite"` — as prescribed (CFG-02)
- `auto_save = true` — persist user-stated inputs automatically (CFG-02)
- SQLite DB lives at default path `~/.zeroclaw/memory.db` (workspace-relative default)

### Observability
- `runtime_trace_mode = "rolling"` — as prescribed (CFG-03); enables `zeroclaw doctor traces` debugging
- `runtime_trace_max_entries = 200` — default; sufficient for debugging cron/tool failures

### Multi-agent IPC
- `enabled = true` — as prescribed (IPC-01)
- `db_path = "~/.zeroclaw/agents.db"` — default path; shared SQLite for any future agent instances on this host (IPC-02)
- `staleness_secs = 300` — 5-minute offline threshold (IPC-01)

### skills/ and cron/ pre-wiring
- Phase 1 creates placeholder empty `skills/` and `cron/` directories in `/etc/nixos/zeroclaw/`
- module.nix wires both via `mkOutOfStoreSymlink` to `~/.zeroclaw/skills/` and `~/.zeroclaw/cron/` (MOD-02)
- Phase 2 populates them with READMEs and scaffolding — symlinks already in place, no rebuild needed

### reference/upstream-docs symlink
- Wire `~/.zeroclaw/reference/upstream-docs/` → `/etc/nixos/zeroclaw/reference/upstream-docs/` via `mkOutOfStoreSymlink`
- The source already symlinks to `~/Projects/zeroclaw/docs/` (DIR-04 — already exists on disk)

### Claude's Discretion
- Exact TOML comment structure and section ordering in config.toml
- Whether to use `auto_approve = []` or `always_ask = []` entries (start empty, expand through runtime approvals)
- `max_actions_per_hour` value (default 20 is fine initially)

</decisions>

<specifics>
## Specific Ideas

- Kiro's primary operations are: git commits/push in /etc/nixos/zeroclaw, reading/writing identity docs, executing zeroclaw commands, running nix builds via sudo nixos-rebuild
- The `gpush` and `gcommit` scripts (from scripts.nix) must be in the allowlist — Kiro uses these for git-first self-modification
- `sudo` in allowed_commands covers `sudo nixos-rebuild switch` for Kiro-initiated NixOS rebuilds (high-risk gate still applies per autonomy level)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `configToml` let-binding in module.nix: already uses `pkgs.writeText` pattern — add new sections to this same string
- `mkOutOfStoreSymlink` pattern: already used for all 6 identity documents — same pattern for skills/, cron/, reference/
- `home.file."..."` entries: established module.nix pattern for deployment

### Established Patterns
- `pkgs.writeText "zeroclaw-config.toml" ''...''` — inline TOML string, all sections go in this one block
- `config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/..."` — canonical pattern for live-editable paths
- EnvironmentFile = `/run/secrets/rendered/zeroclaw.env` — API keys come from sops secrets, not config.toml

### Integration Points
- module.nix imports from `/etc/nixos/zeroclaw/module.nix` → home-manager → ~/.zeroclaw/
- `allowed_commands` must include scripts defined in scripts.nix (gpush, gcommit) since those are on PATH
- `allowed_roots` must cover /etc/nixos/ for zeroclaw's git-first self-modification workflow

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-config-foundation*
*Context gathered: 2026-03-04*
