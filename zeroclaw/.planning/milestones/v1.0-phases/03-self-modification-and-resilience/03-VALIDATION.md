---
phase: 3
slug: self-modification-and-resilience
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-04
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (document audits + CLI commands) |
| **Config file** | none |
| **Quick run command** | `zeroclaw skills list && git log --oneline -5` |
| **Full suite command** | `zeroclaw skills list && zeroclaw cron list && git log --oneline -10` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `zeroclaw skills list && git log --oneline -3`
- **After every plan wave:** Run full suite command above
- **Before `/gsd:verify-work`:** Full suite must return no errors + MOD-04 test must be run
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| AGENTS.md self-mod policy | 03-01 | 1 | MOD-01 | manual | `grep -c "Fully autonomous" documents/AGENTS.md` | ✅ | ✅ green |
| AGENTS.md self-repair hard limits | 03-01 | 1 | RPR-01/02/03 | manual | `grep -c "Hard Limits" documents/AGENTS.md` | ✅ | ✅ green |
| repair-loop skill created | 03-02 | 2 | RPR-01 | cli | `zeroclaw skills list \| grep repair-loop` | ✅ | ✅ green |
| sentinel skill created | 03-02 | 2 | RPR-02 | cli | `zeroclaw skills list \| grep sentinel` | ✅ | ✅ green |
| sentinel cron registered | 03-02 | 2 | RPR-02 | cli | `zeroclaw cron list \| grep sentinel` | ✅ | ✅ green |
| IPC section in CLAUDE.md | 03-03 | 3 | IPC-03 | manual | `grep -c "agents_ipc" CLAUDE.md` | ✅ | ✅ green |
| MOD-04 test run | 03-03 | 3 | MOD-04 | manual | `git log --oneline \| head -5` (verify TEST.md commits) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `skills/repair-loop/` directory created
- [x] `skills/sentinel/` directory created
- [x] Both skills pass `zeroclaw skills audit` before installation

*Wave 0 is structural setup only — no test framework installation needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| AGENTS.md self-modification table | MOD-01 | Document content audit | Read AGENTS.md, verify table covers all 4 change types with "Fully autonomous" for each |
| Self-repair in Hard Limits | RPR-02 | Document framing audit | Confirm self-repair appears in Hard Limits section, not just protocol prose |
| IPC documentation accuracy | IPC-03 | Config reference accuracy | Verify IPC section references actual config keys: `enabled`, `db_path`, `staleness_secs` |
| MOD-04 live test | MOD-04 | Requires Kiro session | Run: `zeroclaw agent -m "Create documents/TEST.md with a timestamped test entry, commit it to git in /etc/nixos/zeroclaw, verify with git log, then delete TEST.md and commit the deletion"`. Verify `git log` shows both commits. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved — Phase 4 Plan 01, 2026-03-05
