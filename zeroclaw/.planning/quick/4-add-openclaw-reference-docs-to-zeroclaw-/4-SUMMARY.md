---
phase: quick-4
plan: 01
subsystem: reference
tags: [symlinks, openclaw, reference, job-search, profile]

requires: []
provides:
  - "Symlink reference/full-profile.md → /etc/nixos/openclaw/reference/full-profile.md"
  - "Symlink reference/reusable-responses.md → /etc/nixos/openclaw/reference/reusable-responses.md"
  - "Updated reference/SUMMARY.md with Personal Reference section and on-demand guidance"
affects: [job-search, application-drafting, kiro-context]

tech-stack:
  added: []
  patterns: ["On-demand reference pattern: symlinks to large context files not auto-loaded into daily context"]

key-files:
  created:
    - reference/full-profile.md (symlink)
    - reference/reusable-responses.md (symlink)
  modified:
    - reference/SUMMARY.md

key-decisions:
  - "Symlinks point directly to openclaw source files — single source of truth, no duplication"
  - "Files documented as on-demand in SUMMARY.md — Kiro reads them only when task requires it, not by default"

requirements-completed: [QUICK-4]

duration: 5min
completed: 2026-03-04
---

# Quick Task 4: Add OpenClaw Reference Docs to ZeroClaw Summary

**Two openclaw reference symlinks (full-profile.md, reusable-responses.md) added to Kiro's reference directory as on-demand context files, documented with load-when guidance in SUMMARY.md**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-04T20:45:00Z
- **Completed:** 2026-03-04T20:50:00Z
- **Tasks:** 1
- **Files modified:** 3 (2 symlinks created, 1 file updated)

## Accomplishments

- Created `reference/full-profile.md` symlink pointing to `/etc/nixos/openclaw/reference/full-profile.md` (8KB — Enrique's profile, resume, career narrative)
- Created `reference/reusable-responses.md` symlink pointing to `/etc/nixos/openclaw/reference/reusable-responses.md` (20KB — polished application responses)
- Updated `reference/SUMMARY.md` with "Personal Reference (On-Demand)" section documenting both files with when-to-use guidance

## Task Commits

1. **Task 1: Create symlinks and update SUMMARY.md** - `4f2b113` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `/etc/nixos/zeroclaw/reference/full-profile.md` — Symlink to openclaw full-profile.md (8KB profile/resume/job search state)
- `/etc/nixos/zeroclaw/reference/reusable-responses.md` — Symlink to openclaw reusable-responses.md (20KB polished application responses)
- `/etc/nixos/zeroclaw/reference/SUMMARY.md` — Appended Personal Reference section with on-demand load guidance

## Decisions Made

- Symlinks point directly to openclaw source — single source of truth, edits in openclaw are immediately reflected
- Documented as "on-demand" in SUMMARY.md so Kiro reads them only when task warrants it, not loaded into every session
- No rebuild required — reference/ is live via mkOutOfStoreSymlink wiring from Phase 1

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Kiro can now load Enrique's full profile and reusable application responses when job search or application tasks arise
- Files are accessible at `reference/full-profile.md` and `reference/reusable-responses.md` relative to the reference directory

---
*Quick Task: quick-4*
*Completed: 2026-03-04*
