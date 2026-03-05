---
phase: 4
slug: sentinel-verification-and-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-04
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual + CLI verification (no automated test suite) |
| **Config file** | None — behavioral/documentation phase |
| **Quick run command** | `zeroclaw cron list && zeroclaw skills list \| grep sentinel` |
| **Full suite command** | `zeroclaw cron list && zeroclaw skills list && zeroclaw memory list && git log --oneline -5` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** `zeroclaw skills list | grep sentinel` (after skill updates), `git log --oneline -3` (after documentation commits)
- **After every plan wave:** Run full suite command above
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | RPR-03 | live-agent | `zeroclaw agent -m "Run the sentinel skill and report what memory_recall returns for 'issue:' prefix"` (observe output) | ✅ sentinel SKILL.md exists | ⬜ pending |
| 4-01-02 | 01 | 1 | RPR-03 | file-check | `ls .planning/phases/03-self-modification-and-resilience/03-VERIFICATION.md` | ❌ Wave 0 | ⬜ pending |
| 4-01-03 | 01 | 1 | RPR-03 | file-audit | `grep "nyquist_compliant" .planning/phases/03-self-modification-and-resilience/03-VALIDATION.md` | ✅ exists, needs update | ⬜ pending |
| 4-01-04 | 01 | 1 | RPR-03 | content-check | `grep -n "\.sh" /etc/nixos/zeroclaw/skills/README.md` | ✅ exists, needs patch | ⬜ pending |
| 4-01-05 | 01 | 1 | RPR-03 | live-agent | Seed test issue via `memory_store`, trigger cron or `zeroclaw agent -m "Run sentinel now"`, observe detection | ✅ sentinel + cron live | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `.planning/phases/03-self-modification-and-resilience/03-VERIFICATION.md` — GSD VERIFICATION.md covering Phase 3 UAT results (source: 03-UAT.md, 6/6 passed)

*All other infrastructure (sentinel skill, cron, VALIDATION.md) already exists from Phase 3 — no additional installs needed before implementation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| memory_recall("issue:") prefix scan confirmed | RPR-03 | Agent tool API — not testable from CLI | Ask ZeroClaw agent to call memory_recall with "issue:" and report result; observe whether prefix or exact match |
| Sentinel end-to-end detection | RPR-03 | Requires live agent session + cron or manual trigger | Seed `memory_store("issue:test-phase4", "...")`, trigger sentinel, confirm SMS/notification sent or detection logged |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
