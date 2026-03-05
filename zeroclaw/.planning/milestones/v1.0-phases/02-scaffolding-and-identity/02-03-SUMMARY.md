---
phase: 02-scaffolding-and-identity
plan: 03
subsystem: identity
tags: [zeroclaw, identity-docs, kiro, cron, skills, openclaw-migration]

# Dependency graph
requires:
  - phase: 01-config-foundation
    provides: documents/ symlink via mkOutOfStoreSymlink so edits are immediately live
  - phase: 02-02
    provides: AGENTS.md audited and cleaned of OpenClaw refs (same wave, IDN-01 shared)
provides:
  - IDENTITY.md updated — Kiro platform reference is ZeroClaw
  - SOUL.md updated — System Access paths zeroclaw; Cron Jobs section rewritten to zeroclaw cron CLI
  - TOOLS.md updated — all openclaw paths, service names, cron management rewritten; Utility Skills reflects current ZeroClaw state
  - USER.md updated — full-profile.md path updated to zeroclaw; Kapso bridge renamed
  - LORE.md updated — all paths, product names, distribution narrative updated to zeroclaw
affects: [03-operational-docs, any future plan loading identity docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cron is managed via zeroclaw cron CLI only — no YAML files, no cron-sync, no file-based definitions"
    - "document/ changes are live-edit (symlink passthrough); module.nix requires nixos-rebuild switch"
    - "Kapso WhatsApp Bridge is now a standalone project — not prefixed with ZeroClaw or OpenClaw"

key-files:
  created: []
  modified:
    - /etc/nixos/zeroclaw/documents/IDENTITY.md
    - /etc/nixos/zeroclaw/documents/SOUL.md
    - /etc/nixos/zeroclaw/documents/TOOLS.md
    - /etc/nixos/zeroclaw/documents/USER.md
    - /etc/nixos/zeroclaw/documents/LORE.md

key-decisions:
  - "Kapso WhatsApp Bridge renamed to standalone project (drop OpenClaw prefix) in USER.md and LORE.md — consistent with LORE.md plan spec"
  - "USER.md had 2 additional OpenClaw refs beyond the 1 planned (personal achievement bullets) — auto-fixed to match must_have truth of zero openclaw refs"
  - "LORE.md Content Pillar #2 'OpenClaw setup' had one unplanned ref — auto-fixed for completeness"

patterns-established:
  - "ZeroClaw cron pattern: zeroclaw cron add '<expr>' --tz '<TZ>' '<command>' for scheduling AI agent sessions"
  - "Not-yet-migrated annotation: append '(not yet migrated)' to reference paths for files confirmed absent from /etc/nixos/zeroclaw/reference/"

requirements-completed: [IDN-01, IDN-02]

# Metrics
duration: 3min
completed: 2026-03-04
---

# Phase 2 Plan 3: Identity Document Audit (5 docs) Summary

**Surgical OpenClaw-to-ZeroClaw audit of 5 identity docs — cron sections rewritten to zeroclaw CLI, all openclaw paths and product names updated, zero openclaw refs remaining across all 6 documents**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-04T23:01:34Z
- **Completed:** 2026-03-04T23:04:28Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Zero openclaw references across all 5 documents (combined with plan 02-02: all 6 identity docs are openclaw-free, IDN-01 complete)
- SOUL.md Cron Jobs section rewritten from YAML+cron-sync workflow to zeroclaw cron CLI with clear examples
- TOOLS.md Cron Management section rewritten to zeroclaw cron CLI; Utility Skills table replaced with current ZeroClaw state (find-skills, skill-creator preloaded)
- All path references in all 5 documents updated to /etc/nixos/zeroclaw/; (not yet migrated) annotations added where files are absent
- Runtime validation: `zeroclaw skills list` and `zeroclaw cron list` both return without errors (IDN-02 confirmed)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix IDENTITY.md and USER.md** - `12de62b` (feat)
2. **Task 2: Rewrite SOUL.md** - `4c531f5` (feat)
3. **Task 3: Update TOOLS.md and LORE.md** - `c022068` (feat)

## Files Created/Modified
- `/etc/nixos/zeroclaw/documents/IDENTITY.md` - "OpenClaw" -> "ZeroClaw" on line 9
- `/etc/nixos/zeroclaw/documents/USER.md` - full-profile.md path updated; Kapso bridge refs renamed
- `/etc/nixos/zeroclaw/documents/SOUL.md` - System Access paths updated; Cron Jobs section fully rewritten to zeroclaw cron CLI
- `/etc/nixos/zeroclaw/documents/TOOLS.md` - all openclaw paths/service names updated; Self-Modification deployment note corrected; Cron Management rewritten; Utility Skills replaced
- `/etc/nixos/zeroclaw/documents/LORE.md` - 8 changes: paths, product names, data paths, distribution narrative

## Decisions Made
- Kapso WhatsApp Bridge is now a standalone project — references updated to "Kapso WhatsApp Bridge" without platform prefix, in both USER.md and LORE.md, consistent with LORE.md plan spec
- The deployment note in TOOLS.md Self-Modification section was updated to accurately describe the two-tier model: documents/ changes are immediately live (symlink), module.nix changes require nixos-rebuild switch

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] USER.md had 2 additional OpenClaw refs beyond the 1 planned**
- **Found during:** Task 1 verification
- **Issue:** grep revealed "OpenClaw Kapso WhatsApp bridge" in Current Situation and Key Differentiators sections — both outside the 1 planned change (Full Profile path). The plan's must_have truth requires zero openclaw refs.
- **Fix:** Renamed both to "Kapso WhatsApp bridge" consistent with LORE.md plan spec (bridge is now standalone project)
- **Files modified:** documents/USER.md
- **Verification:** `grep -ri "openclaw" documents/USER.md` returns nothing
- **Committed in:** 12de62b (Task 1 commit)

**2. [Rule 2 - Missing Critical] LORE.md Content Pillar #2 had one unplanned OpenClaw ref**
- **Found during:** Task 3 verification
- **Issue:** "AI/agent engineering: Technical insights from building agents, OpenClaw setup, automation" — not in the plan's 7-change list
- **Fix:** "OpenClaw setup" -> "ZeroClaw setup"
- **Files modified:** documents/LORE.md
- **Verification:** `grep -ri "openclaw" documents/LORE.md` returns nothing
- **Committed in:** c022068 (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 2 — required to meet the must_have zero-openclaw-refs truth)
**Impact on plan:** Both fixes necessary to satisfy IDN-01 success criteria. No scope creep.

## Issues Encountered
None — all grep verification checks passed after fixes.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All 6 identity documents (including AGENTS.md from plan 02-02) are now openclaw-free
- IDN-01 complete: `grep -ri "openclaw" /etc/nixos/zeroclaw/documents/` returns nothing
- IDN-02 confirmed: `zeroclaw skills list` and `zeroclaw cron list` both work
- Phase 3 can proceed — identity docs are stable and correct

---
*Phase: 02-scaffolding-and-identity*
*Completed: 2026-03-04*
