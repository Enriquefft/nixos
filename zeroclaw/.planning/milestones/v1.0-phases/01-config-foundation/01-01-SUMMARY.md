---
phase: 01-config-foundation
plan: 01
subsystem: infra
tags: [nixos, zeroclaw, toml, home-manager, symlinks, autonomy, ipc, observability]

# Dependency graph
requires: []
provides:
  - Complete zeroclaw config.toml with 5 new sections: autonomy, memory, observability, agent, agents_ipc
  - Workspace symlinks wiring SOUL.md and AGENTS.md to source documents in /etc/nixos/zeroclaw/documents/
  - Reference directory symlink for DIR-04 upstream-docs chain to ~/Projects/zeroclaw/docs
  - Placeholder directories skills/ and cron/ for Phase 2+3 pre-wiring
  - zeroclaw doctor: 22 ok, 3 warnings, 0 errors (acceptable state)
affects: [02-skill-scaffolding, 03-behavioral-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "home-manager mkOutOfStoreSymlink for live-edit files (no rebuild needed for content changes)"
    - "Per-file workspace/ symlinks (not directory-level) to avoid home-manager collision"
    - "pkgs.writeText for config.toml rendered at build time"

key-files:
  created:
    - /etc/nixos/zeroclaw/skills/.gitkeep
    - /etc/nixos/zeroclaw/cron/.gitkeep
  modified:
    - /etc/nixos/zeroclaw/module.nix

key-decisions:
  - "Used per-file symlinks for workspace/SOUL.md and workspace/AGENTS.md (not directory-level) to avoid home-manager collision with zeroclaw-managed workspace/ contents"
  - "forbidden_paths excludes /etc and /home so allowed_roots ([/etc/nixos/, ~/Projects/]) are not blocked"
  - "zeroclaw agent -m 'hello' CLI fails without API key loaded (expected — key injected only via systemd EnvironmentFile and zsh wrapper); verified via HTTP gateway webhook which returns model responses correctly"
  - "No skills/ or cron/ mkOutOfStoreSymlinks added — skills deploy via zeroclaw skills install to workspace/skills/, cron is SQLite-backed"

patterns-established:
  - "Auto-fix Rule 1: Schema required fields (max_cost_per_day_cents, observability backend) must match zeroclaw's Rust deserializer, not just documentation defaults"
  - "Gateway verification: use HTTP /webhook endpoint to test functional response when CLI lacks env-loaded API key"

requirements-completed: [CFG-01, CFG-02, CFG-03, CFG-04, CFG-05, DIR-04, IPC-01, IPC-02, MOD-02]

# Metrics
duration: 6min
completed: 2026-03-04
---

# Phase 1 Plan 1: Config Foundation Summary

**zeroclaw module.nix extended with 5 TOML sections (autonomy, memory, observability, agent, agents_ipc), workspace and reference symlinks wired, doctor shows 22 ok / 3 warnings / 0 errors after clean rebuild**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-04T22:07:21Z
- **Completed:** 2026-03-04T22:13:40Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Appended [autonomy], [memory], [observability], [agent], [agents_ipc] sections to config.toml via module.nix pkgs.writeText block
- Wired ~/.zeroclaw/workspace/SOUL.md and AGENTS.md to /etc/nixos/zeroclaw/documents/ via mkOutOfStoreSymlink (live editing without rebuild)
- Wired ~/.zeroclaw/reference/ to /etc/nixos/zeroclaw/reference/ giving access to upstream-docs symlink chain -> ~/Projects/zeroclaw/docs
- Created skills/ and cron/ placeholder directories for Phase 2+3 pre-wiring
- Full NixOS rebuild completed, zeroclaw doctor passes with exactly 3 non-eliminatable warnings

## Task Commits

Each task was committed atomically:

1. **Task 1: Add 5 TOML config sections to module.nix configToml** - `be4856f` (feat)
2. **Task 2: Wire workspace symlinks, reference dir, create placeholder dirs, rebuild** - `8f4b931` (feat)

## Files Created/Modified

- `/etc/nixos/zeroclaw/module.nix` - Added 5 TOML config sections to configToml + 3 new home.file symlink entries
- `/etc/nixos/zeroclaw/skills/.gitkeep` - Placeholder for Phase 2 skill scaffolding
- `/etc/nixos/zeroclaw/cron/.gitkeep` - Placeholder for Phase 3 cron documentation

## Decisions Made

- **Per-file workspace symlinks:** Used per-file mkOutOfStoreSymlink entries for workspace/SOUL.md and workspace/AGENTS.md rather than a directory-level entry, to avoid home-manager collision with zeroclaw-managed workspace/ contents.
- **forbidden_paths excludes /etc and /home:** The autonomy section's explicit forbidden_paths list omits these two paths so that allowed_roots (["/etc/nixos/", "~/Projects/"]) are not blocked by the default upstream denylist.
- **No symlinks for skills/ or cron/:** Skills deploy via `zeroclaw skills install` to workspace/skills/ (not a watched source dir); cron is SQLite-backed with no file-based format. Only placeholder .gitkeep files created.
- **Gateway functional verification via HTTP:** `zeroclaw agent -m 'hello'` fails without API key when called as bare binary (key only injected via systemd EnvironmentFile and zsh wrapper). Verified functional response via HTTP POST to /webhook which returned `{"model":"glm-5","response":"Hey. What's up?"}`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added missing required field `max_cost_per_day_cents` to [autonomy]**
- **Found during:** Task 2 (rebuild and verify)
- **Issue:** zeroclaw TOML deserializer reported `missing field 'max_cost_per_day_cents'` at [autonomy] section — the field is required despite having a documented default of 500
- **Fix:** Added `max_cost_per_day_cents = 500` to the [autonomy] block in module.nix
- **Files modified:** /etc/nixos/zeroclaw/module.nix
- **Verification:** Rebuild succeeded, zeroclaw doctor loaded config without parse errors
- **Committed in:** `8f4b931` (Task 2 commit)

**2. [Rule 1 - Bug] Added missing required field `backend` to [observability]**
- **Found during:** Task 2 (second rebuild after first fix)
- **Issue:** zeroclaw TOML deserializer reported `missing field 'backend'` at [observability] section — also required despite documented default of "none"
- **Fix:** Added `backend = "none"` to the [observability] block in module.nix
- **Files modified:** /etc/nixos/zeroclaw/module.nix
- **Verification:** Rebuild succeeded, zeroclaw doctor reports 22 ok, 3 warnings, 0 errors
- **Committed in:** `8f4b931` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs — schema required fields not matching documentation defaults)
**Impact on plan:** Both fixes were necessary for the config to parse at all. The plan's TOML sections were otherwise correct and complete. No scope creep.

## Issues Encountered

- `zeroclaw agent -m 'hello'` cannot be run as bare binary in this execution environment because the API key env var is only injected via systemd EnvironmentFile and the zsh wrapper function. Verified functional API response instead via HTTP POST to gateway /webhook endpoint, which returned a valid model response.

## User Setup Required

None - no external service configuration required. The zeroclaw systemd service already handles secret injection via /run/secrets/rendered/zeroclaw.env.

## Next Phase Readiness

- Phase 1 foundation complete: zeroclaw gateway configured, doctor clean, autonomy paths allow /etc/nixos/zeroclaw and ~/Projects/
- skills/ and cron/ placeholders exist for Phase 2+3 wiring
- Blocker from STATE.md: validate that `zeroclaw skills list` accepts the skills/ symlink before depending on it in Phase 2 (reject_symlink_tools_dir concern)
- Blocker from STATE.md: confirm cron definition format via `zeroclaw cron --help` before Phase 3 planning

---
*Phase: 01-config-foundation*
*Completed: 2026-03-04*
