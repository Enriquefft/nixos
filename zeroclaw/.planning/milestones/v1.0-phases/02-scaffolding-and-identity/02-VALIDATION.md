---
phase: 2
slug: scaffolding-and-identity
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-04
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual CLI validation (ZeroClaw CLI + grep — no automated test framework for documentation phase) |
| **Config file** | none — validation is live ZeroClaw CLI |
| **Quick run command** | `zeroclaw skills list && zeroclaw cron list` |
| **Full suite command** | `zeroclaw doctor && zeroclaw skills list && zeroclaw cron list && grep -ri "openclaw" /etc/nixos/zeroclaw/documents/ && echo "Audit: PASS" \|\| echo "Audit: FAIL - openclaw refs remain"` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `zeroclaw skills list && zeroclaw cron list`
- **After every plan wave:** Run full suite command above
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | DIR-01 | smoke | `zeroclaw skills list` | ❌ W0 | ⬜ pending |
| 2-01-02 | 01 | 1 | DIR-02 | smoke | `zeroclaw cron list` | ❌ W0 | ⬜ pending |
| 2-01-03 | 01 | 1 | DIR-03, MOD-03 | smoke + manual | `test -f /etc/nixos/zeroclaw/CLAUDE.md && echo PASS` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 1 | IDN-01, IDN-02 | unit + smoke | `grep -ri "openclaw" /etc/nixos/zeroclaw/documents/ && echo FAIL \|\| echo PASS` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `skills/README.md` — must exist to pass DIR-01 smoke test
- [ ] `cron/README.md` — must exist to pass DIR-02 smoke test
- [ ] `CLAUDE.md` — must exist to pass DIR-03/MOD-03 smoke test

*Wave 0 = the content creation tasks themselves. No test framework install needed — using ZeroClaw CLI + grep.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CLAUDE.md contains rebuild vs live-edit table | MOD-03 | Content quality check — grep can't verify completeness | Open CLAUDE.md, confirm rebuild-required vs live-edit table present with correct files listed |
| skills/README.md enables Kiro to create skill without guidance | DIR-01 | Qualitative sufficiency — a human/agent must judge | Read skills/README.md and confirm it contains: SKILL.md format, directory structure, create steps, zeroclaw CLI commands |
| cron/README.md enables Kiro to create cron job without guidance | DIR-02 | Qualitative sufficiency | Read cron/README.md and confirm it covers: zeroclaw cron add syntax, schedule format, list/remove commands |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
