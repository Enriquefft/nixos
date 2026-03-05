---
phase: 02-scaffolding-and-identity
plan: 01
subsystem: docs
tags: [zeroclaw, skills, cron, claude, documentation, operational-guide]

# Dependency graph
requires:
  - phase: 01-config-foundation
    provides: module.nix wiring, symlinks for documents/ and reference/, placeholder skills/ and cron/ dirs
provides:
  - skills/README.md — full operational guide for creating and deploying ZeroClaw skills
  - cron/README.md — full operational guide for managing cron jobs via zeroclaw CLI
  - CLAUDE.md — agent operational guide with deployment model and file map
affects:
  - 02-02 (identity document updates will reference CLAUDE.md and the deployment model)
  - 03-ipc (IPC docs will cross-reference CLAUDE.md for agent operational context)
  - Any agent or Kiro session that reads these docs before making changes

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Three-file doc scaffold: skills/README.md + cron/README.md + CLAUDE.md for agent onboarding"
    - "Deployment model table as primary agent orientation tool (rebuild vs live-edit)"

key-files:
  created:
    - /etc/nixos/zeroclaw/skills/README.md
    - /etc/nixos/zeroclaw/cron/README.md
    - /etc/nixos/zeroclaw/CLAUDE.md
  modified: []

key-decisions:
  - "CLAUDE.md covers both coding agents and Kiro — single file, dual audience, no duplication"
  - "skills/README.md includes no-symlinks-inside-skill-packages rule prominently (security audit rejects them)"
  - "cron/README.md includes SQLite schema as a power-user section — transparency without encouraging direct DB writes"
  - "Anti-patterns section in cron/README.md lists OpenClaw patterns explicitly so agents do not regress"

patterns-established:
  - "Deployment model table: canonical pattern for communicating rebuild vs live-edit in all future CLAUDE.md files"
  - "skills/README.md links: skills audit before install is always required — never skip for security"
  - "No YAML cron: ZeroClaw cron is CLI-only/SQLite — any file-based cron approach is incorrect"

requirements-completed: [DIR-01, DIR-02, DIR-03, MOD-03]

# Metrics
duration: 2min
completed: 2026-03-04
---

# Phase 2 Plan 01: Scaffolding and Identity Summary

**Three operational guide files created — skills/README.md (audit-to-install workflow), cron/README.md (SQLite-backed CLI scheduling with anti-patterns), and CLAUDE.md (rebuild-vs-live-edit table with full file map)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-04T23:01:26Z
- **Completed:** 2026-03-04T23:04:07Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `skills/README.md` with SKILL.md and SKILL.toml format documentation, annotated examples from research, six-step install workflow, and CLI quick reference table
- Created `cron/README.md` with 5-field cron syntax, all CLI subcommands, four concrete workflow examples (daily AI session, 30-min interval, one-time job, shell automation), SQLite schema section, and anti-patterns for deprecated OpenClaw approaches
- Created `CLAUDE.md` with deployment model table (7 rows covering every key file), annotated directory tree, build commands, and dual-audience operational guide (Kiro for skills/cron, coding agents for NixOS testing)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create skills/README.md** - `ec84bd4` (feat)
2. **Task 2: Create cron/README.md** - `511392b` (feat)
3. **Task 3: Create CLAUDE.md** - `c6e8179` (feat)

## Files Created/Modified

- `/etc/nixos/zeroclaw/skills/README.md` — Full operational guide for skill creation and deployment (SKILL.md format, SKILL.toml format, install workflow, CLI reference)
- `/etc/nixos/zeroclaw/cron/README.md` — Full operational guide for cron job management (schedule syntax, all CLI subcommands, workflow examples, anti-patterns)
- `/etc/nixos/zeroclaw/CLAUDE.md` — Agent operational guide covering deployment model (rebuild vs live-edit), file map, build commands, and agent workflows for both Kiro and coding agents

## Decisions Made

- CLAUDE.md serves both coding agents and Kiro — no separate files, one authoritative reference
- skills/README.md leads with the format comparison table (SKILL.md vs SKILL.toml) to orient agents quickly
- cron/README.md includes SQLite schema as a transparency section, with explicit "do not write directly" warning
- Anti-patterns section in cron/README.md explicitly lists cron-sync, cron-manager, YAML files, direct DB writes — prevents OpenClaw regression
- No-symlinks-inside-skill-packages rule is prominent in skills/README.md because zeroclaw skills audit rejects them and this is non-obvious

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 2, Plan 02 (identity document updates) can proceed — CLAUDE.md is in place as the deployment model reference
- All six identity documents are ready for audit and OpenClaw reference removal
- zeroclaw skills list and zeroclaw cron list both confirmed working (3 skills, no cron jobs, no errors)

---
*Phase: 02-scaffolding-and-identity*
*Completed: 2026-03-04*

## Self-Check: PASSED

- FOUND: /etc/nixos/zeroclaw/skills/README.md
- FOUND: /etc/nixos/zeroclaw/cron/README.md
- FOUND: /etc/nixos/zeroclaw/CLAUDE.md
- FOUND: .planning/phases/02-scaffolding-and-identity/02-01-SUMMARY.md
- Commits verified: ec84bd4, 511392b, c6e8179, e2c7bbe
