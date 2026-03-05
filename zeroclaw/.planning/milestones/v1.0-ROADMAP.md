# Roadmap: ZeroClaw Infrastructure

## Overview

Three phases to deliver a robust, extensible foundation for the Kiro agent. Phase 1 wires the complete gateway configuration and symlink deployment model — without it nothing is verifiable. Phase 2 builds the scaffolding, CLAUDE.md, and audited identity documents Kiro reads at runtime. Phase 3 establishes the behavioral constitution and self-repair protocol that govern how Kiro self-modifies without human oversight.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Config Foundation** - Wire the complete config.toml and module.nix deployment model so the gateway passes zero-warning validation (completed 2026-03-04)
- [x] **Phase 2: Scaffolding and Identity** - Build directory structure, CLAUDE.md, and audited identity documents accessible at runtime via symlinks (completed 2026-03-04)
- [x] **Phase 3: Self-Modification and Resilience** - Establish the behavioral constitution and self-repair protocol that govern Kiro's autonomous operation (completed 2026-03-05)
- [x] **Phase 4: Sentinel Verification and Cleanup** - Verify sentinel automated detection works end-to-end, close Phase 3 documentation gaps (completed 2026-03-05)

## Phase Details

### Phase 1: Config Foundation
**Goal**: The ZeroClaw gateway is fully configured, passes zero-warning health checks, and all live-editable paths are wired via mkOutOfStoreSymlink
**Depends on**: Nothing (first phase)
**Requirements**: CFG-01, CFG-02, CFG-03, CFG-04, CFG-05, DIR-04, IPC-01, IPC-02, MOD-02
**Success Criteria** (what must be TRUE):
  1. `zeroclaw doctor` reports at most 3 warnings (api_key env, no channels, no channel-components — non-eliminatable with kapso-whatsapp bridge architecture) after a clean `nixos-rebuild switch`
  2. `zeroclaw agent -m "hello"` returns a successful response from the Z.AI model (not a 404 or auth error)
  3. Kiro can execute an approved shell command (e.g., `git status`) in a live session without permission errors
  4. Changes made to files in `documents/` source directory are immediately visible at `~/.zeroclaw/documents/` without a rebuild
  5. The `reference/upstream-docs/` symlink resolves to `~/Projects/zeroclaw/docs` and ZeroClaw docs are readable
**Plans**: 1 plan

Plans:
- [x] 01-01-PLAN.md — Add 5 TOML config sections + wire workspace symlinks and reference dir, rebuild to verify

### Phase 2: Scaffolding and Identity
**Goal**: The skills and cron directories exist with documented conventions, CLAUDE.md provides complete agent guidance, and all six identity documents are audited and ZeroClaw-compatible
**Depends on**: Phase 1
**Requirements**: DIR-01, DIR-02, DIR-03, IDN-01, IDN-02, MOD-03
**Success Criteria** (what must be TRUE):
  1. `zeroclaw skills list` resolves successfully and shows the skills directory (validates symlink security is not blocking it)
  2. Any agent opening this repo can read CLAUDE.md and immediately know which files require rebuild vs live-edit
  3. All six identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) contain no stale OpenClaw references and load correctly when Kiro starts
  4. The skills/ and cron/ READMEs document conventions clearly enough that Kiro can create a new skill or cron job by reading them without human guidance
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md — Create skills/README.md, cron/README.md, and CLAUDE.md (scaffolding + deployment model)
- [ ] 02-02-PLAN.md — Full rewrite of AGENTS.md for ZeroClaw-native tooling
- [ ] 02-03-PLAN.md — Surgical audit of IDENTITY, SOUL, TOOLS, USER, LORE documents

### Phase 3: Self-Modification and Resilience
**Goal**: Kiro's behavioral constitution is documented and tested — git-first self-modification is demonstrated end-to-end, and the self-repair mandate is unconditional and durable
**Depends on**: Phase 2
**Requirements**: MOD-01, MOD-04, RPR-01, RPR-02, RPR-03, IPC-03
**Success Criteria** (what must be TRUE):
  1. Kiro edits a test identity document in `/etc/nixos/zeroclaw/documents/`, commits it, and `git log` shows the commit without human intervention
  2. AGENTS.md explicitly distinguishes what Kiro can change autonomously vs what requires user approval, with no ambiguous cases
  3. When Kiro encounters any failure (config, runtime, or infrastructure), it files a durable record and attempts repair before asking the user
  4. An additional ZeroClaw agent instance can be described and configured using the IPC documentation in CLAUDE.md
**Plans**: 4 plans

Plans:
- [ ] 03-01-PLAN.md — Add self-modification policy table and strengthen self-repair mandate in AGENTS.md
- [ ] 03-02-PLAN.md — Create and install repair-loop skill (callable repair_loop tool)
- [ ] 03-03-PLAN.md — Create sentinel skill and register 2-hour error sentinel cron job
- [ ] 03-04-PLAN.md — Add Multi-Agent IPC section to CLAUDE.md + MOD-04 live test checkpoint

### Phase 4: Sentinel Verification and Cleanup
**Goal**: Confirm sentinel automated error detection works end-to-end, close RPR-03 partial gap, and clear Phase 3 documentation debt
**Depends on**: Phase 3
**Requirements**: RPR-03
**Gap Closure**: Closes gaps from v1.0 audit
**Success Criteria** (what must be TRUE):
  1. `memory_recall("issue:")` prefix scan behavior confirmed — either works as expected or sentinel SKILL.md updated to use a confirmed pattern
  2. Sentinel cron fires and detects at least one seeded test issue (live end-to-end test)
  3. Phase 3 VERIFICATION.md generated and committed
  4. Phase 3 VALIDATION.md signed off (`nyquist_compliant: true`)
  5. skills/README.md updated to accurately reflect that `.sh` files cannot be placed inside skill packages
**Plans**: 1 plan

Plans:
- [ ] 04-01-PLAN.md — Verify memory_recall API, fix sentinel if needed, generate Phase 3 VERIFICATION.md, sign off VALIDATION.md, fix skills/README.md docs gap

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Config Foundation | 1/1 | Complete    | 2026-03-04 |
| 2. Scaffolding and Identity | 2/3 | Complete    | 2026-03-04 |
| 3. Self-Modification and Resilience | 4/4 | Complete   | 2026-03-05 |
| 4. Sentinel Verification and Cleanup | 1/1 | Complete   | 2026-03-05 |
