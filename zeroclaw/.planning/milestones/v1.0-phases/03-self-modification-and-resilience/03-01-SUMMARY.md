---
phase: 03-self-modification-and-resilience
plan: "01"
subsystem: identity
tags: [agents, self-modification, self-repair, autonomy, zeroclaw, documents]

# Dependency graph
requires:
  - phase: 02-scaffolding-and-identity
    provides: Rewritten AGENTS.md with Self-Repair Protocol using memory_store
provides:
  - AGENTS.md Self-Modification Policy table — 4 change types, all fully autonomous
  - Hard Limits self-repair mandate — unconditional scope with absolute language
  - repair_loop skill reference in both Hard Limits and Self-Repair Protocol
  - ZeroClaw restart command prescribed in Hard Limits
affects:
  - 03-02 (repair-loop skill — policy table is the behavioral contract it enforces)
  - 03-03 (sentinel cron — repair mandate policy it operates under)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Self-modification is constitutional, not ad-hoc — policy table is the contract"
    - "Hard Limits use absolute language (Never, non-negotiable) for unconditional rules"
    - "File → fix → report sequence enforced in Hard Limits, not just guidelines"

key-files:
  created: []
  modified:
    - documents/AGENTS.md

key-decisions:
  - "Self-repair scope broadened from internal tools to any issue Kiro caused or can fix"
  - "repair_loop skill referenced in Hard Limits and Self-Repair Protocol as preferred invocation over direct memory_store"
  - "ZeroClaw runtime restart prescribed as one-shot: restart once, if still down report immediately"
  - "Self-Modification Policy placed between When Enrique is Silent and Self-Repair Protocol for logical flow"

patterns-established:
  - "Constitutional policy: make behavioral mandates explicit in AGENTS.md Hard Limits with no-exceptions language"
  - "Skill references in documents: point to skill name in prose so Kiro invokes it when available"

requirements-completed: [MOD-01, RPR-01, RPR-02, RPR-03]

# Metrics
duration: 2min
completed: 2026-03-05
---

# Phase 3 Plan 01: Self-Modification and Self-Repair Constitutional Policy Summary

**AGENTS.md updated with explicit self-modification autonomy table (4 change types, all fully autonomous) and unconditional self-repair mandate elevated to Hard Limits with ZeroClaw restart command and repair_loop skill references**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-04T23:59:23Z
- **Completed:** 2026-03-05T00:00:54Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added Self-Modification Policy section to AGENTS.md with explicit 4-row autonomy table — identity docs, config.toml, skills, and .nix files all marked fully autonomous
- Elevated self-repair from guideline to Hard Limits — 5 new entries with absolute language (Never, non-negotiable) covering unconditional scope, ZeroClaw restart, system issues, and unfixable issues
- Updated Self-Repair Protocol opening scope from "internal tools" to "any issue it caused or can fix" and added repair_loop skill as preferred invocation in Step 1

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Self-Modification Policy section** - `38bab86` (feat) — Task 1 and Task 2 were committed together as a single atomic change
2. **Task 2: Elevate self-repair mandate to Hard Limits** - `38bab86` (feat) — combined with Task 1
3. **Task 3: Commit AGENTS.md changes** - `38bab86` (feat) — the commit itself

Note: Tasks 1 and 2 are both document edits to AGENTS.md committed atomically in a single commit per the plan's Task 3 instruction.

## Files Created/Modified

- `/etc/nixos/zeroclaw/documents/AGENTS.md` — Added Self-Modification Policy section (4-row table + git-first rule), appended 5 entries to Hard Limits, updated Self-Repair Protocol opening line and Step 1 repair_loop reference

## Decisions Made

- Self-Modification Policy placed between "When Enrique is Silent" and "Self-Repair Protocol" for logical document flow — policy table provides context before the protocol details
- repair_loop skill referenced by name in both Hard Limits and Self-Repair Protocol Step 1 to ensure Kiro invokes the skill when available rather than calling memory_store directly
- ZeroClaw restart prescribed as one-shot only (restart once, report if still down) to prevent infinite loops
- Self-repair scope change ("internal tools" to "any issue Kiro caused or can fix") aligns with Plan 03-02 repair-loop skill scope

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. AGENTS.md is live immediately via mkOutOfStoreSymlink — no rebuild needed.

## Next Phase Readiness

- Constitutional policy is in place — AGENTS.md now contains the behavioral mandate that Plans 02 and 03 enforce mechanically
- Plan 03-02 (repair-loop skill) provides the mechanical enforcement mechanism referenced in Hard Limits
- Plan 03-03 (sentinel cron) will operate under the self-repair mandate established here

---
*Phase: 03-self-modification-and-resilience*
*Completed: 2026-03-05*
