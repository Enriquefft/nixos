# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.0 — Kiro MVP

**Shipped:** 2026-03-05
**Phases:** 4 | **Plans:** 10 | **Timeline:** 1 day

### What Was Built

- ZeroClaw config.toml wired with 5 sections (autonomy, memory, observability, agent, IPC) — Kiro passes health checks
- Operational docs: CLAUDE.md deployment guide, skills/README.md, cron/README.md
- All 6 identity documents migrated from OpenClaw to ZeroClaw-native tooling
- Self-modification policy table + unconditional self-repair mandate in AGENTS.md
- repair-loop skill: callable `repair_loop` tool for durable issue filing before repair
- Sentinel cron: 2-hour automated error detection, repair invocation, WhatsApp escalation
- Multi-Agent IPC configured and documented
- Live verification: memory prefix scan confirmed, sentinel E2E detection passed

### What Worked

- **GSD wave execution** — parallel plan execution within phases kept context lean and progress fast
- **Checkpoint gates for human-action tasks** — the pattern of stopping and handing off interactive ZeroClaw commands to the user worked well; no guessing at live session results
- **Phase 4 gap closure loop** — the gaps_found → plan-phase --gaps → execute-phase --gaps-only cycle closed all verification gaps cleanly
- **SUMMARY.md as evidence chain** — detailed summaries made the verifier's job tractable across 10 plans

### What Was Inefficient

- **memory_store permission gate discovery** — the first checkpoint attempt (Phase 4 plan 01) was blocked by the interactive permission gate; needed a second plan and session to resolve. Could have been caught earlier by reading AGENTS.md permission model before planning the test
- **`mkOutOfStoreSymlink` → `home.activation` pivot** — the symlink approach required a quick fix mid-milestone (quick-3). Pre-reading NixOS home-manager symlink docs would have avoided this
- **`max_actions_per_hour` missing field** — added as a quick fix when `zeroclaw cron list` failed. A quick `zeroclaw --version` + config schema check at project start would have caught this
- **Phase 2 plan count mismatch** — roadmap showed 2/3 complete at milestone completion even though all 3 plans had SUMMARYs; minor tracking artifact

### Patterns Established

- `bin/` directory for skill scripts — `.sh` files rejected inside skill packages; `bin/<script>.sh` + absolute SKILL.toml path is the approved pattern
- `home.activation` for document symlinks — not `mkOutOfStoreSymlink` (multi-hop issues)
- Checkpoint type `human-action` for ZeroClaw agent sessions — coding agents cannot run `zeroclaw agent`; always route to user
- `memory_recall("issue:")` prefix scan pattern — confirmed working; sentinel skill correctly uses this
- Test seeding + cleanup protocol — seed issue → trigger sentinel → verify detection → mark resolved; prevents lingering test artifacts firing real alerts

### Key Lessons

1. **Interactive ZeroClaw sessions require the user** — `zeroclaw agent` cannot be invoked by Claude Code (no API key in that context). Any plan task requiring a live ZeroClaw session must be `type="checkpoint:human-action"`.
2. **Config schema changes need pre-flight** — before any ZeroClaw CLI usage, verify `zeroclaw cron list` works to catch missing required config fields early.
3. **Permission gates are session-type-specific** — `memory_store` requires user approval in interactive sessions but cron-triggered sessions (sentinel) are unaffected. This matters for test design.
4. **Infrastructure quick fixes accumulate** — 4 `/gsd:quick` fixes were needed mid-milestone. Consider a "pre-flight" phase that validates the ZeroClaw runtime state before deeper implementation phases.

### Cost Observations

- Model mix: 100% sonnet (all orchestrators and subagents)
- Sessions: ~6 Claude Code sessions across 1 day
- Notable: GSD's subagent architecture kept orchestrator context at ~10-15%; fresh 200k per executor meant no context degradation across 10 plans

---

## Cross-Milestone Trends

| Metric | v1.0 |
|--------|------|
| Plans/phase avg | 2.5 |
| Quick fixes needed | 4 |
| Verification gaps closed | 2 |
| Timeline | 1 day |
| Human-action checkpoints | 3 |
