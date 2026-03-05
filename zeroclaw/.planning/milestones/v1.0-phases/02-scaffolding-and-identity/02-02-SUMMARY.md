---
phase: 02-scaffolding-and-identity
plan: "02"
subsystem: identity
tags: [agents, zeroclaw, cron, skills, memory, identity-documents]

requires:
  - phase: 02-scaffolding-and-identity/02-01
    provides: "documents/ directory with symlinked identity docs confirmed working"

provides:
  - "AGENTS.md fully rewritten with ZeroClaw-native tooling — no OpenClaw references"
  - "System-First Rule table maps to zeroclaw cron, zeroclaw skills, zeroclaw memory"
  - "Self-Repair Protocol uses memory_store/memory_recall for durable issue tracking"
  - "Durable Tracking section documents zeroclaw memory as the interim task-queue replacement"

affects:
  - 02-scaffolding-and-identity (remaining identity doc rewrites in 02-03 through 02-06)
  - Phase 3 behavioral docs

tech-stack:
  added: []
  patterns:
    - "ZeroClaw memory (memory_store/memory_recall) as interim durable tracking mechanism"
    - "zeroclaw cron CLI as sole cron management mechanism — no YAML files"
    - "zeroclaw skills install as sole skill deployment mechanism"

key-files:
  created: []
  modified:
    - /etc/nixos/zeroclaw/documents/AGENTS.md

key-decisions:
  - "Replace Task Queue Protocol with Durable Tracking section — zeroclaw memory is the interim mechanism, task-queue skill is v2/CRN-01"
  - "Retain 'task-queue skill' as a concept name in v2 scope notes — only CLI command invocations are removed"
  - "Self-Repair Protocol keeps same logic (file → fix → update → report → fall back) but records to memory_store instead of task-queue"

patterns-established:
  - "Identity document updates: rewrite stale tool references first, update paths second, preserve semantically correct sections"
  - "ZeroClaw-native framing: write as if ZeroClaw is the only system that has ever existed — no backwards-compat stubs"

requirements-completed: [IDN-01, IDN-02]

duration: 2min
completed: "2026-03-04"
---

# Phase 2 Plan 02: AGENTS.md Identity Rewrite Summary

**AGENTS.md fully rewritten — all OpenClaw tool references replaced with zeroclaw cron/skills/memory CLI; zero openclaw strings remain**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-04T23:01:38Z
- **Completed:** 2026-03-04T23:03:43Z
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Replaced the entire System-First Rule table: `cron-manager` → `zeroclaw cron add`, `skill-scaffold` → `zeroclaw skills install`, `task-queue` → `zeroclaw memory (memory_store)`, NixOS path updated to `/etc/nixos/zeroclaw/CLAUDE.md`
- Updated "Never ask, just do" list: cron entry now references `zeroclaw cron add/remove/pause/resume` with explicit "no YAML files" note; config path updated to `/etc/nixos/zeroclaw/CLAUDE.md`
- Replaced Hard Limits cron rule: YAML+cron-sync prohibition now reads "zeroclaw cron CLI only, all state lives in SQLite"
- Rewrote Self-Repair Protocol: `task-queue add/resolve` replaced with `memory_store/memory_recall`; same fix logic preserved
- Replaced Task Queue Protocol section with Durable Tracking section: documents `memory_store`/`memory_recall` usage patterns, priority conventions, and notes CRN-01 as v2 scope
- All `/etc/nixos/openclaw/` paths updated to `/etc/nixos/zeroclaw/`
- Runtime confirmed healthy: `zeroclaw skills list` returns 3 skills, `zeroclaw cron list` returns without errors

## Task Commits

1. **Task 1: Full rewrite of AGENTS.md for ZeroClaw-native tooling** - `7892e03` (feat)

**Plan metadata:** pending final docs commit

## Files Created/Modified

- `/etc/nixos/zeroclaw/documents/AGENTS.md` - Kiro's operational constitution, fully rewritten for ZeroClaw-native tooling

## Decisions Made

- **Durable Tracking replaces Task Queue Protocol:** `task-queue` skill does not exist in ZeroClaw. Rather than leaving a broken protocol, the section was redesigned around `zeroclaw memory` (memory_store/memory_recall) with a note that a dedicated task-queue skill is v2/CRN-01. The protocol logic (file → fix → update → report → fall back) is preserved identically.
- **"task-queue skill" concept name retained in v2 notes:** The success criterion prohibits task-queue CLI command invocations. Naming a future v2 skill "task-queue" in scope notes is not a CLI invocation — this is accurate documentation of the roadmap.
- **No backwards compatibility stubs:** Written as if ZeroClaw is the only system that has ever existed — no "this replaces OpenClaw" language anywhere.

## Deviations from Plan

None — plan executed exactly as written. The single task's verification commands all passed.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- AGENTS.md is now ZeroClaw-native and can be used as Kiro's operational constitution immediately
- Remaining 5 identity documents (IDENTITY.md, SOUL.md, TOOLS.md, USER.md, LORE.md) still need their OpenClaw references updated — these are covered in plans 02-03 through 02-07
- Wave 1 audit (`grep -ri "openclaw" /etc/nixos/zeroclaw/documents/`) will not pass until all 6 documents are updated

---
*Phase: 02-scaffolding-and-identity*
*Completed: 2026-03-04*
