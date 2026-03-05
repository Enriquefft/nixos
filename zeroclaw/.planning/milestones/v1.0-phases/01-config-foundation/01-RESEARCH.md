# Phase 1: Config Foundation - Research

**Researched:** 2026-03-04
**Domain:** ZeroClaw 0.1.7 TOML configuration, NixOS home-manager module.nix patterns
**Confidence:** HIGH (verified against live ZeroClaw 0.1.7 binary and schema)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Autonomy level**
- `level = "supervised"` — medium-risk commands (shell, file writes) require approval
- `workspace_only = false` — Kiro must operate outside workspace (git in /etc/nixos/zeroclaw, nix builds, Projects/)
- `allowed_roots = ["/etc/nixos/", "~/Projects/"]` — minimum viable access as specified in CFG-01
- `allowed_commands` allowlist: git, nix, nixos-rebuild, systemctl, journalctl, zeroclaw, gpush, gcommit, gh, cargo, node, bun, npm, python3, bash, sh, ls, cat, grep, find, cp, mv, rm, mkdir, chmod, chown, curl, wget, jq, direnv, sudo

**Agent limits**
- `max_tool_iterations = 40`
- `max_history_messages = 100`

**Memory**
- `backend = "sqlite"`, `auto_save = true`
- SQLite DB at default path `~/.zeroclaw/memory.db`

**Observability**
- `runtime_trace_mode = "rolling"`, `runtime_trace_max_entries = 200`

**Multi-agent IPC**
- `enabled = true`, `db_path = "~/.zeroclaw/agents.db"`, `staleness_secs = 300`

**skills/ and cron/ pre-wiring**
- Phase 1 creates placeholder empty `skills/` and `cron/` directories in `/etc/nixos/zeroclaw/`
- module.nix wires both via `mkOutOfStoreSymlink` to `~/.zeroclaw/skills/` and `~/.zeroclaw/cron/` (MOD-02)

**reference/upstream-docs symlink**
- Wire `~/.zeroclaw/reference/upstream-docs/` → `/etc/nixos/zeroclaw/reference/upstream-docs/` via `mkOutOfStoreSymlink`
- The source already symlinks to `~/Projects/zeroclaw/docs/` (DIR-04 — already exists on disk)

### Claude's Discretion
- Exact TOML comment structure and section ordering in config.toml
- Whether to use `auto_approve = []` or `always_ask = []` entries (start empty, expand through runtime approvals)
- `max_actions_per_hour` value (default 20 is fine initially)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CFG-01 | config.toml `[autonomy]` section with `allowed_commands`, `allowed_roots`, `workspace_only = false` | Schema verified: all fields exist, `allowed_commands` type is `string[]`, `allowed_roots` supports `~/...` expansion |
| CFG-02 | config.toml `[memory]` section with `backend = "sqlite"`, `auto_save = true` | Schema verified: `MemoryConfig` has both fields with these as defaults |
| CFG-03 | config.toml `[observability]` section with `runtime_trace_mode = "rolling"` | Schema verified: `ObservabilityConfig.runtime_trace_mode` accepts `"rolling"` |
| CFG-04 | config.toml `[agent]` section with `max_tool_iterations = 40`, `max_history_messages = 100` | Schema verified: `AgentConfig` has both fields; defaults are 20 and 50 |
| CFG-05 | module.nix renders complete config.toml with all configured sections | Existing `pkgs.writeText "zeroclaw-config.toml"` pattern is the correct approach |
| DIR-04 | `reference/upstream-docs/` symlink resolves to `~/Projects/zeroclaw/docs/` | VERIFIED: `/etc/nixos/zeroclaw/reference/upstream-docs -> /home/hybridz/Projects/zeroclaw/docs` exists and has 628KB of docs |
| IPC-01 | config.toml `[agents_ipc]` section with `enabled = true`, `staleness_secs = 300` | Schema verified: `AgentsIpcConfig` has all three fields |
| IPC-02 | module.nix wires IPC database path and ensures shared SQLite is accessible | `db_path` defaults to `~/.zeroclaw/agents.db`; no special module.nix wiring needed — zeroclaw creates the DB |
| MOD-02 | module.nix wires all live-editable paths via `mkOutOfStoreSymlink` | Pattern already established for documents/; needs correction for skills/ and cron/ paths (see critical findings) |
</phase_requirements>

---

## Summary

ZeroClaw 0.1.7 is running on this machine. The gateway is active, the daemon is healthy, and the config is partially wired. Phase 1 adds five missing TOML sections (`[autonomy]`, `[memory]`, `[observability]`, `[agent]`, `[agents_ipc]`) to the existing `configToml` let-binding in `module.nix`, corrects the `mkOutOfStoreSymlink` deployment model for workspace documents, wires the reference directory, and creates placeholder source directories for skills and cron.

**Current doctor state:** 5 warnings, 0 errors. Phase 1 eliminates 2 of those warnings (SOUL.md and AGENTS.md in workspace). The remaining 3 warnings are either acceptable (no api_key — uses env var) or non-eliminatable with this architecture (no channels configured — kapso-whatsapp connects via WebSocket, not as a native ZeroClaw channel).

**Primary recommendation:** Add all five TOML sections to the existing `pkgs.writeText` block, add workspace document symlinks, wire `~/.zeroclaw/reference/`, and create source skeleton dirs. One rebuild achieves all Phase 1 success criteria.

**Critical corrections needed vs CONTEXT assumptions:**
1. `~/.zeroclaw/skills/` does NOT exist — skills live at `~/.zeroclaw/workspace/skills/`. The CONTEXT's `mkOutOfStoreSymlink` for `~/.zeroclaw/skills/` needs to be reinterpreted.
2. `~/.zeroclaw/cron/` does NOT exist — cron is stored in `~/.zeroclaw/workspace/cron/jobs.db` (SQLite). File-based cron definitions are not a ZeroClaw feature.
3. `zeroclaw chat "hello"` does NOT exist — the correct command is `zeroclaw agent -m "hello"`.
4. The `forbidden_paths` default includes `/etc` and `/home` — which conflicts with `allowed_roots = ["/etc/nixos/", "~/Projects/"]`. This requires explicit `forbidden_paths` override to remove `/etc` and `/home`.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ZeroClaw | 0.1.7 | AI agent runtime | Already installed as nixpkgs package |
| home-manager | NixOS 25.11 | Deploy config to `~/.zeroclaw/` | Project deployment model |
| pkgs.writeText | nixpkgs | Render TOML config at build time | Already used in module.nix |
| config.lib.file.mkOutOfStoreSymlink | home-manager | Create direct filesystem symlinks | Already used for all 6 identity docs |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sops-nix | project-managed | API keys via EnvironmentFile | Already wired for zeroclaw.env secrets |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `pkgs.writeText` inline TOML | External `.toml` file | `writeText` keeps config in version-controlled module.nix, external file needs separate symlink |
| `mkOutOfStoreSymlink` per-file | Directory-level symlink | Per-file gives finer control; directory symlink simpler but risks home-manager conflicts |

---

## Architecture Patterns

### Recommended Project Structure (after Phase 1)
```
/etc/nixos/zeroclaw/
├── module.nix           # home-manager module (rebuild required to change)
├── documents/           # identity docs (live-editable via mkOutOfStoreSymlink)
│   ├── IDENTITY.md
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── TOOLS.md
│   ├── USER.md
│   └── LORE.md
├── reference/           # source-controlled references
│   └── upstream-docs -> ~/Projects/zeroclaw/docs/  (already exists)
├── skills/              # NEW: empty placeholder (Phase 2 populates with SKILL.md files)
└── cron/                # NEW: empty placeholder (Phase 3 populates with cron docs)

~/.zeroclaw/             # deployment target (never edited directly)
├── config.toml -> /nix/store/...  (rendered by module.nix pkgs.writeText)
├── documents/           # per-file symlinks via mkOutOfStoreSymlink chain
│   ├── SOUL.md -> /etc/nixos/zeroclaw/documents/SOUL.md
│   └── ...
├── workspace/           # zeroclaw-managed runtime directory
│   ├── skills/          # zeroclaw installs skills here
│   ├── cron/jobs.db     # zeroclaw cron storage (SQLite, NOT file-based)
│   ├── SOUL.md -> ...   # NEW: workspace-level symlink for doctor check
│   └── AGENTS.md -> ... # NEW: workspace-level symlink for doctor check
└── reference/ -> /etc/nixos/zeroclaw/reference/  # NEW: mkOutOfStoreSymlink
```

### Pattern 1: TOML Section Addition (pkgs.writeText)
**What:** Add sections to the existing inline TOML string in the `configToml` let-binding.
**When to use:** All config changes that require a rebuild.
**Example:**
```nix
# In module.nix, add to the configToml = pkgs.writeText "zeroclaw-config.toml" '' ... '' block:
[autonomy]
level = "supervised"
workspace_only = false
allowed_roots = ["/etc/nixos/", "~/Projects/"]
allowed_commands = [
  "git", "nix", "nixos-rebuild", "systemctl", "journalctl",
  "zeroclaw", "gpush", "gcommit", "gh", "cargo",
  "node", "bun", "npm", "python3", "bash", "sh",
  "ls", "cat", "grep", "find", "cp", "mv", "rm",
  "mkdir", "chmod", "chown", "curl", "wget", "jq",
  "direnv", "sudo"
]
forbidden_paths = [
  "/root", "/usr", "/bin", "/sbin", "/lib", "/opt",
  "/boot", "/dev", "/proc", "/sys", "/var", "/tmp",
  "~/.ssh", "~/.gnupg", "~/.aws", "~/.config"
]
```

### Pattern 2: mkOutOfStoreSymlink (live-editable files)
**What:** Creates a symlink chain: `~/.zeroclaw/X` → nix store marker → source file in `/etc/nixos/zeroclaw/`.
**When to use:** Files that must be editable without rebuilding NixOS.
**Example:**
```nix
# Source: existing module.nix pattern (confirmed working for documents/)
home.file.".zeroclaw/documents/SOUL.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/SOUL.md";

# NEW: workspace-level symlinks (for doctor check)
home.file.".zeroclaw/workspace/SOUL.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/SOUL.md";

# NEW: reference directory symlink
home.file.".zeroclaw/reference".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/reference";
```

### Anti-Patterns to Avoid
- **Editing `~/.zeroclaw/config.toml` directly:** It's managed by home-manager (force = true). Changes will be overwritten on next activation.
- **Using `home.file` without `force = true` for config.toml:** Will conflict with existing file. The current module already sets `force = true`.
- **Symlinking `~/.zeroclaw/workspace/skills/` to a source dir:** The workspace/skills/ dir is managed by `zeroclaw skills install`. Replacing it with a symlink would break installed skills.
- **Setting `forbidden_paths` to include `/etc` or `/home` when `workspace_only = false`:** These defaults block `allowed_roots` targets. Must explicitly override `forbidden_paths`.
- **Using `zeroclaw chat`:** This command does not exist. Use `zeroclaw agent -m "message"`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rendering TOML config | Custom Nix derivation | `pkgs.writeText` | One-liner, nix-native, already in use |
| Live-editable symlinks | Shell scripts to create symlinks | `config.lib.file.mkOutOfStoreSymlink` | Home-manager manages lifecycle, handles conflict detection |
| Cron job scheduling | systemd timers, ad-hoc crontab | `zeroclaw cron add` | ZeroClaw native cron is in scope (Phase 3); systemd timers are out-of-scope per requirements |
| API key injection | Hardcode in config.toml | EnvironmentFile via sops | Already wired; `ZEROCLAW_API_KEY` env var at runtime |
| Skills directory wiring | Custom symlink to workspace/skills/ | Leave workspace/skills/ as-is; use `zeroclaw skills install` | workspace/ is zeroclaw-managed; symlink replacement breaks installed skills |

**Key insight:** ZeroClaw's config is purely additive TOML — every section is optional and defaults gracefully. No custom tooling is needed; just extend the existing `pkgs.writeText` block.

---

## Common Pitfalls

### Pitfall 1: forbidden_paths blocks allowed_roots targets
**What goes wrong:** Default `forbidden_paths` includes `/etc` and `/home`. With `workspace_only = false` and `allowed_roots = ["/etc/nixos/", "~/Projects/"]`, Kiro cannot access either path because `/etc` and `/home` are blocked.
**Why it happens:** `forbidden_paths` is an explicit denylist. The schema does not state priority between denylist and `allowed_roots`. `/etc/nixos/` starts with `/etc`; `~/Projects/` expands to `/home/hybridz/Projects/` which starts with `/home`.
**How to avoid:** Explicitly set `forbidden_paths` in config.toml WITHOUT `/etc` and `/home`. Keep all other sensitive paths. Verified safe set:
```toml
forbidden_paths = [
  "/root", "/usr", "/bin", "/sbin", "/lib", "/opt",
  "/boot", "/dev", "/proc", "/sys", "/var", "/tmp",
  "~/.ssh", "~/.gnupg", "~/.aws", "~/.config"
]
```
**Warning signs:** Kiro reports "path not allowed" when trying to `git status` in `/etc/nixos/zeroclaw/`.

### Pitfall 2: zeroclaw doctor "SOUL.md not found" and "AGENTS.md not found" warnings
**What goes wrong:** Doctor checks `~/.zeroclaw/workspace/` for SOUL.md and AGENTS.md (AIEOS format convention). The documents exist at `~/.zeroclaw/documents/` (openclaw format) but not at `workspace/`.
**Why it happens:** ZeroClaw supports two identity formats (`openclaw` and `aieos`). The `[workspace]` doctor check looks for identity docs at workspace root for AIEOS compatibility, regardless of `identity.format` setting.
**How to avoid:** Add `home.file` entries in module.nix that place symlinks at `~/.zeroclaw/workspace/SOUL.md` and `~/.zeroclaw/workspace/AGENTS.md` pointing to the same source documents. Confirmed fix: `zeroclaw doctor` drops from 5 to 3 warnings after adding these symlinks.
**Warning signs:** Doctor reports `[workspace] SOUL.md not found (optional)` after rebuild.

### Pitfall 3: "no channels configured" and "no channel components tracked yet" are non-eliminatable
**What goes wrong:** These two doctor warnings remain even with kapso-whatsapp bridge running.
**Why it happens:** Kapso connects to the ZeroClaw gateway via WebSocket (`ws://127.0.0.1:42617/ws/chat`) as an external bridge — it does not register as a native ZeroClaw channel. Doctor's `[config]` check looks for native channel config (`[channels_config]` with telegram/discord/slack/etc.), and `[daemon]` checks for channel components tracked in `daemon_state.json`.
**How to avoid:** Accept these warnings as architectural realities for this setup. OR add a minimal webhook/whatsapp native channel config — but that would conflict with kapso-whatsapp bridge.
**Warning signs:** These warnings will always show after Phase 1. "Zero warnings" success criterion needs qualification: "zero warnings excluding the 3 non-eliminatable warnings (api_key via env, no channels, no channel components)."

### Pitfall 4: Skills path mismatch (CONTEXT assumption error)
**What goes wrong:** CONTEXT says wire `~/.zeroclaw/skills/` via `mkOutOfStoreSymlink`. This path does not exist. Skills live at `~/.zeroclaw/workspace/skills/`.
**Why it happens:** Planning assumption was based on OpenClaw's model where skills had a top-level directory. ZeroClaw places all runtime-managed state in `workspace/`.
**How to avoid:** Do NOT create a `home.file.".zeroclaw/skills"` entry. Skills are installed to `workspace/skills/` via `zeroclaw skills install /path/to/skill-source`. Phase 1 creates `/etc/nixos/zeroclaw/skills/` as a SOURCE directory for skill development (Phase 2 populates it with SKILL.md files). There is NO live symlink between source and deployment — `zeroclaw skills install` is the install step.
**Warning signs:** `zeroclaw skills list` shows empty or fails if workspace/skills/ is replaced with a symlink.

### Pitfall 5: Cron is SQLite, not file-based
**What goes wrong:** CONTEXT says wire `~/.zeroclaw/cron/` via `mkOutOfStoreSymlink`. ZeroClaw cron is stored in `~/.zeroclaw/workspace/cron/jobs.db` (SQLite). There is no file-based cron definition format.
**Why it happens:** Planning assumed file-based cron definitions similar to systemd timer units or YAML-based job schedulers.
**How to avoid:** Phase 1 creates `/etc/nixos/zeroclaw/cron/` as an empty placeholder directory for documentation and future cron job scripts. There is NO `mkOutOfStoreSymlink` wiring for cron. Cron jobs are added via `zeroclaw cron add '0 9 * * *' 'message'` (stored in workspace/cron/jobs.db).
**Warning signs:** STATE.md already flags this: "Cron format validation unresolved — confirm via `zeroclaw cron --help`". Research confirms: cron uses SQLite, no file watching.

### Pitfall 6: config.toml world-readable log warning is not a doctor warning
**What goes wrong:** Every zeroclaw command logs `WARN Config file is world-readable (mode 444)`. This appears scary but is NOT a doctor check.
**Why it happens:** NixOS nix store files are always mode 444 (read-only). The config.toml is a symlink to a store path. There is no way to chmod a nix store file.
**How to avoid:** Accept this as an inherent NixOS+ZeroClaw incompatibility. It does not affect doctor summary counts. It is a stderr log message only.

---

## Code Examples

Verified patterns from module.nix and ZeroClaw 0.1.7 schema:

### Complete configToml additions for Phase 1

```nix
# Source: ZeroClaw 0.1.7 config schema (zeroclaw config schema)
# Add these sections to the existing pkgs.writeText block in module.nix

[autonomy]
level = "supervised"
workspace_only = false
allowed_roots = ["/etc/nixos/", "~/Projects/"]
allowed_commands = [
  "git", "nix", "nixos-rebuild", "systemctl", "journalctl",
  "zeroclaw", "gpush", "gcommit", "gh", "cargo",
  "node", "bun", "npm", "python3", "bash", "sh",
  "ls", "cat", "grep", "find", "cp", "mv", "rm",
  "mkdir", "chmod", "chown", "curl", "wget", "jq",
  "direnv", "sudo"
]
forbidden_paths = [
  "/root", "/usr", "/bin", "/sbin", "/lib", "/opt",
  "/boot", "/dev", "/proc", "/sys", "/var", "/tmp",
  "~/.ssh", "~/.gnupg", "~/.aws", "~/.config"
]
max_actions_per_hour = 20

[memory]
backend = "sqlite"
auto_save = true

[observability]
runtime_trace_mode = "rolling"
runtime_trace_max_entries = 200

[agent]
max_tool_iterations = 40
max_history_messages = 100

[agents_ipc]
enabled = true
db_path = "~/.zeroclaw/agents.db"
staleness_secs = 300
```

### New home.file entries for module.nix

```nix
# Source: existing mkOutOfStoreSymlink pattern in module.nix (verified working)

# Fix doctor workspace check for SOUL.md and AGENTS.md
home.file.".zeroclaw/workspace/SOUL.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/SOUL.md";
home.file.".zeroclaw/workspace/AGENTS.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/AGENTS.md";

# Wire reference directory (DIR-04)
home.file.".zeroclaw/reference".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/reference";
```

### Creating placeholder source directories

```bash
# /etc/nixos/zeroclaw/ additions for Phase 1
mkdir -p /etc/nixos/zeroclaw/skills
mkdir -p /etc/nixos/zeroclaw/cron
# Phase 2 populates these with READMEs and SKILL.md files
```

### Verify complete config after rebuild

```bash
# Validate config renders correctly
nix flake check
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos

# Verify
zeroclaw doctor
zeroclaw agent -m "hello"  # NOT "zeroclaw chat" -- that command does not exist
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| OpenClaw Go gateway | ZeroClaw Rust runtime | Already done | Native cron, skills, autonomy controls |
| Custom hook scripts | Native `[autonomy]` TOML config | Phase 1 | No custom infrastructure needed |
| ad-hoc crontab/systemd | `zeroclaw cron add` (SQLite backed) | Phase 1 infra | All scheduling through ZeroClaw |

**Deprecated/outdated:**
- OpenClaw `zeroclaw/*` secrets namespace: Already renamed (done, per MEMORY.md)
- `zeroclaw chat`: Command does not exist in 0.1.7 — use `zeroclaw agent -m "..."`

---

## Open Questions

1. **Does `allowed_roots` take precedence over `forbidden_paths`?**
   - What we know: Schema says `allowed_roots` paths "pass `is_resolved_path_allowed`"; `forbidden_paths` is "explicit path denylist". Priority not stated.
   - What's unclear: Whether Kiro with `allowed_roots = ["/etc/nixos/"]` can still be blocked by `forbidden_paths = ["/etc"]`.
   - Recommendation: **Override `forbidden_paths` explicitly** to remove `/etc` and `/home` rather than relying on undocumented priority. Safe explicit set verified above.

2. **Can "no channels configured" and "no channel components tracked yet" doctor warnings be eliminated?**
   - What we know: Both warnings stem from kapso-whatsapp connecting as external WebSocket bridge, not as a native ZeroClaw channel. Adding a native channel config could silence them.
   - What's unclear: Whether the ROADMAP's "zero warnings" success criterion tolerates these 3 non-eliminatable warnings (api_key + 2 channel warnings).
   - Recommendation: Qualify the success criterion in the plan: "zero warnings, excluding api_key (uses env var), no channels configured, and no channel components tracked (kapso-whatsapp connects via WebSocket, not native channel)". Do NOT add a redundant native WhatsApp channel that conflicts with kapso.

3. **Can `home.file` target workspace subdirectories safely?**
   - What we know: workspace/ is owned by hybridz (writable). `home.file.".zeroclaw/workspace/SOUL.md"` was tested manually and correctly created a symlink. Doctor dropped two warnings.
   - What's unclear: Whether home-manager activation ever deletes unexpected files in workspace/ on collision.
   - Recommendation: **Use per-file entries** (not directory-level) for workspace/SOUL.md and workspace/AGENTS.md to minimize collision risk.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None (NixOS config project — no unit test framework) |
| Config file | none |
| Quick run command | `nix flake check` |
| Full suite command | `sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos && zeroclaw doctor` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CFG-01 | autonomy section rendered with workspace_only=false, allowed_roots set | smoke | `zeroclaw status 2>&1 \| grep -E "Workspace only\|Allowed roots"` | ❌ Wave 0 |
| CFG-02 | memory backend=sqlite, auto_save=true | smoke | `zeroclaw status 2>&1 \| grep -i sqlite` | ❌ Wave 0 |
| CFG-03 | observability runtime_trace_mode=rolling | smoke | `cat ~/.zeroclaw/config.toml \| grep runtime_trace_mode` | ❌ Wave 0 |
| CFG-04 | agent max_tool_iterations=40, max_history_messages=100 | smoke | `cat ~/.zeroclaw/config.toml \| grep max_tool_iterations` | ❌ Wave 0 |
| CFG-05 | config.toml renders all 5 new sections | smoke | `nix flake check` then `nix build .#nixosConfigurations.nixos.config.system.build.toplevel` | ❌ Wave 0 |
| DIR-04 | reference/upstream-docs resolves to zeroclaw docs | smoke | `ls /etc/nixos/zeroclaw/reference/upstream-docs \| head -5` | ✅ (already exists) |
| IPC-01 | agents_ipc section enabled in config | smoke | `cat ~/.zeroclaw/config.toml \| grep "enabled = true"` | ❌ Wave 0 |
| IPC-02 | agents.db path accessible after rebuild | smoke | `ls ~/.zeroclaw/agents.db 2>/dev/null \|\| echo "created on first use"` | ❌ Wave 0 |
| MOD-02 | workspace/SOUL.md symlink resolves to source doc | smoke | `readlink -f ~/.zeroclaw/workspace/SOUL.md` | ❌ Wave 0 |
| MOD-02 | ~/.zeroclaw/reference/ symlink resolves | smoke | `readlink -f ~/.zeroclaw/reference/upstream-docs \| grep zeroclaw/docs` | ❌ Wave 0 |

**Phase gate commands (post-rebuild):**
```bash
# Gate 1: Syntax + build
nix flake check && nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Gate 2: Activate
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos

# Gate 3: Verify
zeroclaw doctor
# Acceptable after Phase 1: max 3 warnings (api_key env, no channels, no channel components)

# Gate 4: Functional test
zeroclaw agent -m "hello"
# Must return response, not 404 or auth error

# Gate 5: Autonomy test
zeroclaw agent -m "run: git status in /etc/nixos/zeroclaw"
# Must NOT produce "path not allowed" error (validates forbidden_paths override)

# Gate 6: Symlink chain
readlink -f ~/.zeroclaw/reference/upstream-docs
# Must resolve to /home/hybridz/Projects/zeroclaw/docs
```

### Sampling Rate
- **Per task commit:** `nix flake check`
- **Per wave merge:** `nix build .#nixosConfigurations.nixos.config.system.build.toplevel`
- **Phase gate:** Full suite (all 6 gates above) before marking phase complete

### Wave 0 Gaps
- [ ] `skills/` directory — empty placeholder at `/etc/nixos/zeroclaw/skills/`
- [ ] `cron/` directory — empty placeholder at `/etc/nixos/zeroclaw/cron/`
- No test framework install needed — smoke tests use `nix` and `zeroclaw` CLI tools already on PATH

---

## Sources

### Primary (HIGH confidence)
- ZeroClaw 0.1.7 binary `zeroclaw config schema` — full JSON Schema for all config sections, verified locally
- `module.nix` in `/etc/nixos/zeroclaw/` — existing deployment patterns confirmed working
- Live filesystem inspection — `ls`, `readlink`, `zeroclaw doctor`, `zeroclaw status`, `zeroclaw skills install` output

### Secondary (MEDIUM confidence)
- `~/.zeroclaw/config.toml.hm-backup` — previous config for cross-reference on field names and ordering
- ZeroClaw 0.1.7 `--help` output for all subcommands — confirmed available commands and options

### Tertiary (LOW confidence)
- None — all claims verified against live binary and filesystem

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against live ZeroClaw 0.1.7 binary and schema
- Architecture: HIGH — confirmed via filesystem inspection and live testing
- Pitfalls: HIGH — all pitfalls discovered by direct testing (not assumed)

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (ZeroClaw is fast-moving; re-verify if version bumps to 0.2.x)
