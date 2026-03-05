# Project Research Summary

**Project:** ZeroClaw / Kiro — Autonomous Personal AI Agent Infrastructure
**Domain:** NixOS-deployed autonomous AI agent (chief-of-staff)
**Researched:** 2026-03-04
**Confidence:** HIGH

## Executive Summary

This project is a migration and hardening of an existing autonomous personal AI agent (previously OpenClaw, now ZeroClaw) running on NixOS. Kiro operates as a chief-of-staff for Enrique: scanning jobs, scheduling tasks, synthesizing research, sending WhatsApp briefings, and managing its own configuration via git-first self-modification. The core infrastructure (gateway daemon, WhatsApp channel via Kapso bridge, model providers via Z.AI, web search via Brave) is already deployed. What is missing is the completeness layer: autonomy config, memory persistence, observability, security rails, and the 13 cron jobs plus 7 skills that make the agent proactively useful rather than just responsive.

The recommended approach is a strict two-tier architecture: structural config (model providers, gateway port, channel wiring, autonomy policy) lives in `module.nix` and requires `nixos-rebuild switch` to change; everything Kiro edits at runtime (identity documents, skills, cron job definitions) is wired via `mkOutOfStoreSymlink` to `/etc/nixos/zeroclaw/` and takes effect immediately without a rebuild. This boundary is the load-bearing architectural decision. Violating it — putting mutable content in `config.toml`, or editing `~/.zeroclaw/` directly — causes silent overwrites and breaks self-modification. All self-modification goes through git, making the repo the audit log and rollback mechanism.

The key risks are concentrated in Phase 1. Seven of ten documented pitfalls are config-layer issues that must be resolved before any cron jobs or skills are added: wrong Z.AI wire API (returns 404 with `openai-responses`, must use `chat_completions`), missing `allowed_commands` (shell tools fail silently), `max_tool_iterations = 20` (cron jobs truncate mid-task), empty `allowed_numbers` on WhatsApp (deny-all by default), missing NixOS-specific `forbidden_paths`, symlink security potentially blocking the `skills/` directory, and `phone_number_id` needing to be quoted as a string. Fix these first, validate with `zeroclaw doctor` + live tests, then add jobs and skills incrementally.

## Key Findings

### Recommended Stack

The stack is NixOS home-manager (25.11) as the deployment layer, ZeroClaw daemon mode as the runtime, sops-nix for secret delivery, and git as the audit trail and rollback mechanism. No new technologies are needed — everything is already installed. The work is configuration completeness, not installation. `mkOutOfStoreSymlink` is the critical home-manager primitive that enables live-editable files (documents, skills, cron) without triggering a NixOS rebuild every time Kiro self-modifies.

**Core technologies:**
- `home-manager 25.11` + `mkOutOfStoreSymlink`: renders `config.toml`, wires systemd user services, creates live symlinks — the declarative deployment model
- `zeroclaw daemon`: correct production entrypoint (not `zeroclaw gateway` which omits channels and cron scheduler)
- `sops-nix` + `EnvironmentFile`: only correct secrets pattern on NixOS — Nix store is world-readable
- `git` (via `/etc/nixos` repo): audit log, rollback, and single source of truth for all Kiro config changes
- `systemd user services`: gateway + kapso bridge run as `hybridz`, not root — correct isolation model
- Z.AI with `wire_api = "chat_completions"`: confirmed working; `openai-responses` returns 404 (documented in MEMORY.md)

### Expected Features

**Must have (table stakes — Phase 1):**
- `[autonomy]` section with explicit `allowed_commands`, `allowed_roots`, `forbidden_paths` (NixOS-extended), `auto_approve` — agent cannot execute tools without it
- `[memory]` with `backend = "sqlite"`, `auto_save = true` — agent forgets everything between sessions without it
- `[observability]` with `runtime_trace_mode = "rolling"` — blind debugging without it, especially for cron
- `[security.estop]` enabled — kill-switch for runaway autonomous sessions before enabling full autonomy
- `[agent]` with `max_tool_iterations = 50-80` — default of 20 silently truncates complex cron sessions
- `[cost]` with `daily_limit_usd = 1.00`, `monthly_limit_usd = 30.00` — matches Z.AI $30/month budget
- All 6 identity documents wired as live symlinks (IDENTITY, SOUL, AGENTS, USER, TOOLS, LORE)
- CLAUDE.md for the `/etc/nixos/zeroclaw/` directory (agents working on this infra need it)
- Upstream docs symlink (`reference/upstream-docs/` → `~/Projects/zeroclaw/docs/`)

**Should have (Phase 2 — jobs and skills):**
- `task-queue` skill — required dependency for all cron jobs (the durable cross-session work tracker)
- Core cron jobs: `morning-briefing`, `end-of-day`, `task-worker` — minimum viable schedule
- Job scanning skills: `job-scanner`, `job-tracker` — highest-value cron jobs for Enrique
- RSS/research skills: `rss-reader`, `git-activity` — enable `content-scout` and `skill-scan` jobs
- Remaining 10 cron jobs migrated and validated one-by-one
- `[[model_routes]]` with `hint:fast` and `hint:reasoning` route hints — decouple cron prompts from model names

**Defer (Phase 3 — intelligence layer):**
- `[query_classification]` + smart model routing — defer until token costs are a real concern
- Sub-agent delegation (`[agents.researcher]`, `[agents.coder]`) — add after single-agent is stable
- `[security.otp]` for shell/browser gating — add if prompt injection risk materializes
- `track-price-drops` skill (BTC monitoring) — stub exists, low priority
- Nostr channel — fallback if WhatsApp reliability becomes an issue

### Architecture Approach

The architecture is a strict three-layer system: source of truth (`/etc/nixos/zeroclaw/`, git-tracked), deployment (`~/.zeroclaw/`, generated by NixOS build), and runtime (ZeroClaw daemon + Kapso bridge, systemd user services). The boundary between layers is enforced by NixOS build mechanics: `config.toml` is rendered from `module.nix` with `force = true` (overwritten on every rebuild), while `documents/`, `skills/`, and `cron/` are live symlinks that make edits in the source tree immediately visible at the deployment path. The Kapso bridge is declared `PartOf` the gateway service so lifecycle is coupled correctly.

**Major components:**
1. `module.nix` — the only file requiring `nixos-rebuild switch`; owns structural config (providers, ports, autonomy policy, service declarations)
2. `documents/` (symlinked) — Kiro's runtime identity; live-editable by Kiro without rebuild
3. `skills/` (symlinked) — SKILL.toml manifests + implementations; live-editable, deployed via ZeroClaw skill subsystem
4. `cron/` (symlinked) — job definitions picked up by ZeroClaw scheduler; live-editable
5. `zeroclaw-gateway.service` — persistent daemon; gateway + channels + cron scheduler as one process
6. `kapso-whatsapp-bridge.service` — WhatsApp relay; `PartOf` gateway, crash-isolated with `StartLimitBurst`
7. `zeroclaw.env` (sops-rendered) — all secrets injected via `EnvironmentFile`, never in Nix store

### Critical Pitfalls

1. **Wrong Z.AI wire API (`openai-responses`)** — set `wire_api = "chat_completions"` explicitly; validate with `zeroclaw chat "hello"` before anything else; this is already burned in MEMORY.md
2. **`allowed_commands` empty = shell tools silently fail** — ZeroClaw is secure-by-default; empty list means no shell access; populate explicitly in Phase 1 with `["git", "zeroclaw", "bash", "cat", "ls", "grep", "find", "jq", "curl", "gpush", "systemctl", "journalctl"]` and expand as needed
3. **Editing `~/.zeroclaw/` directly** — `config.toml` has `force = true` and is overwritten on every rebuild; document in CLAUDE.md and AGENTS.md that `~/.zeroclaw/` is read-only from Kiro's perspective
4. **`max_tool_iterations = 20` silently truncates cron** — complex jobs (job-scan, morning-briefing) exceed 20 tool calls; set to 50-80 before first cron job runs
5. **Missing NixOS-specific `forbidden_paths`** — ZeroClaw defaults cover standard Unix paths but not `/run/secrets/`, `~/.config/sops/`, `/nix/store/`; add these explicitly to prevent Kiro reading sops age keys
6. **Symlink security may block `skills/` directory** — ZeroClaw WASM runtime defaults have `reject_symlink_tools_dir = true`; must validate with `zeroclaw skills list` after first rebuild before building skills; if blocked, redesign the path mapping in `module.nix`
7. **`phone_number_id` bare integer breaks YAML parsing** — always quote it: `phone_number_id: "123456789012345"`; already documented in MEMORY.md from OpenClaw era

## Implications for Roadmap

Based on research, the dependency graph is clear: you cannot run cron jobs until the gateway is fully configured; you cannot run skills until the autonomy config allows shell execution; you cannot trust cron job output until observability is enabled; and you cannot self-modify safely until the git-first workflow is documented and enforced. This drives a 4-phase structure.

### Phase 1: Config Foundation

**Rationale:** Seven of ten pitfalls are config-layer issues. Nothing else can be validated until the gateway is properly configured, secrets are wiring correctly, autonomy rules allow shell execution, and safety rails are in place. This phase has no external dependencies — it is pure `module.nix` work.
**Delivers:** A fully configured ZeroClaw gateway that passes `zeroclaw doctor` with zero warnings, can hold a real conversation via WhatsApp and CLI, and has shell autonomy working in a test session.
**Addresses:** Autonomy config (P1), memory persistence (P1), observability (P1), emergency stop (P1), cost limits (P1), upstream docs symlink + CLAUDE.md (P1), all symlink wiring declared
**Avoids:** Wrong API type (Pitfall 1), missing `allowed_commands` (Pitfall 3), missing NixOS forbidden_paths (Pitfall 4), `phone_number_id` parsing (Pitfall 6), `max_tool_iterations` too low (Pitfall 7), empty `allowed_numbers` (Pitfall 10)
**Validation:** `zeroclaw doctor` zero warnings; `zeroclaw chat "hello"` returns successful Z.AI response; send WhatsApp message and receive response; shell tool call succeeds in test session; `zeroclaw estop` / `zeroclaw estop resume` cycle tested

### Phase 2: Identity and Self-Modification Workflow

**Rationale:** Before adding jobs or skills, Kiro's operational directives must be complete and the self-modification workflow must be documented and tested. AGENTS.md is particularly important — it is the behavioral constitution that governs how Kiro handles approval gates, git commits, and self-repair. Symlink security for `skills/` must also be validated here, before Phase 3 builds on top of it.
**Delivers:** Complete identity document set (AGENTS.md with full operational directives, TOOLS.md with current capability inventory), validated `mkOutOfStoreSymlink` behavior for all three paths (documents, skills, cron), and a demonstrated Kiro self-modification round-trip (edit → commit → verify in git log).
**Addresses:** Self-modification without git commit (Pitfall 5), OpenClaw patterns applied to ZeroClaw (Pitfall 9), identity document system completeness
**Avoids:** Behavioral drift from incomplete AGENTS.md; symlink security blocking skills (Pitfall 8) — validate here before Phase 3 depends on it
**Validation:** Kiro edits a test document, commits it, and `git log` shows the commit; `zeroclaw skills list` resolves correctly via symlink; AGENTS.md documents the self-modification workflow explicitly

### Phase 3: Cron Jobs and Skills Migration

**Rationale:** Skills and cron jobs share the same dependency chain (task-queue must exist before any cron job runs) and should be built together incrementally, not all at once. Start with the minimum viable schedule (morning-briefing, end-of-day, task-worker) and the skills they depend on. Add remaining jobs one-by-one with validation before the next.
**Delivers:** Operational cron schedule with at minimum: task-queue skill, task-worker cron, morning-briefing, end-of-day. Then: job-scanner + job-tracker skills and their associated cron jobs (job-scan-am, job-scan-pm). Then: rss-reader, git-activity skills and their consumers (content-scout, skill-scan, paper-scout-*). Finally: remaining jobs (follow-up-enforcer, self-audit, build-in-public).
**Addresses:** Task queue skill (P1 dependency), core cron jobs (P1), job-scanning skills (P2), RSS/research skills (P2), remaining 10 jobs (P2)
**Avoids:** Migrating all 13 jobs at once (creates undebuggable mess); applying OpenClaw YAML+sync patterns (Pitfall 9 — use ZeroClaw native cron format); cron jobs firing before config is validated (UX pitfall)
**Validation:** Each cron job fires at least once with complete (non-truncated) output visible in runtime traces; task-queue entries are created and resolved correctly; morning WhatsApp briefing arrives formatted correctly

### Phase 4: Intelligence Layer

**Rationale:** Once the core agent is stable and cron jobs are running reliably, add the optimization layer: smart model routing by task type, sub-agent delegation for scoped research tasks, and OTP gating if prompt injection risk has materialized. These are all deferred intentionally — adding routing complexity before single-agent stability creates debugging hell.
**Delivers:** `[[model_routes]]` with `hint:fast` / `hint:reasoning` routing, optional `[query_classification]` for automatic routing, optional sub-agent delegation config, optional OTP gating for shell/browser actions.
**Addresses:** Model routing (P3), sub-agent delegation (P3), OTP gating (P3)
**Avoids:** Premature optimization; sub-agent debugging before single-agent is stable

### Phase Ordering Rationale

- Phase 1 must come first because no other work is verifiable until the gateway is correctly configured. Every pitfall in Phase 1 causes silent failures — you won't know things are broken.
- Phase 2 before Phase 3 because AGENTS.md governs how Kiro handles Phase 3 work (self-repair, git commits, approval gates). Building skills before the behavioral constitution is documented risks creating undocumented habits.
- Phase 3 is internally ordered by dependency: task-queue skill must exist before any cron job runs; core jobs (briefing, EOD, task-worker) before specialized jobs (job-scan, content-scout).
- Phase 4 is deferred deliberately: model routing before cost data is known is premature; sub-agent delegation before single-agent is reliable creates compounded failures.

### Research Flags

Phases needing deeper research during planning:
- **Phase 3 (Cron Jobs + Skills):** Each of the 13 cron jobs needs analysis against ZeroClaw's native cron format vs OpenClaw's YAML+sync format. The skill system (SKILL.toml manifests) has different conventions from OpenClaw's SKILL.md + run.ts. Each job migration should be treated as a mini-research task. Recommend `/gsd:research-phase` before planning individual jobs if the ZeroClaw cron format is not yet fully understood.
- **Phase 3 (Symlink Security for Skills):** Pitfall 8 flags that `reject_symlink_tools_dir = true` may block the `skills/` symlink. This needs a live validation step in Phase 2. If blocked, the module.nix wiring strategy needs redesign before Phase 3 depends on it.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Config Foundation):** All config sections are documented in the live ZeroClaw config-reference (verified Feb 25 2026). The module.nix TOML template pattern is already established. No unknown unknowns.
- **Phase 2 (Identity + Self-Modification):** Pattern is fully defined (mkOutOfStoreSymlink, git-first, AGENTS.md as behavioral constitution). Content work, not architectural work.
- **Phase 4 (Intelligence Layer):** ZeroClaw native support for model routes, query classification, and sub-agents is documented. Deferred but not unknown.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Primary source: live ZeroClaw config-reference (verified Feb 25 2026) + current module.nix. No speculation. |
| Features | HIGH | Based on live config schema, first-hand OpenClaw system as prior art, and PROJECT.md requirements. MVP vs v2 distinction is clear. |
| Architecture | HIGH | Based on current deployed module.nix + operations runbook. The two-tier boundary pattern is implemented and working. |
| Pitfalls | HIGH | Mix of first-hand pain (OpenClaw post-mortem, MEMORY.md session-learned), official docs defaults, and NixOS-specific gotchas. All cross-referenced with live config. |

**Overall confidence:** HIGH

### Gaps to Address

- **Cron format validation:** It is not fully confirmed whether ZeroClaw cron definitions load from TOML files in a watched directory, from YAML, or only from CLI commands (`zeroclaw cron add`). STACK.md notes this: "Confirm via `zeroclaw config schema` whether cron definitions load from files or only from CLI commands." Resolve with `zeroclaw cron --help` and `zeroclaw config schema` before Phase 3 planning.
- **Symlink security for skills directory:** Whether `reject_symlink_tools_dir` applies to ZeroClaw's native SKILL.toml skills (not just WASM modules) is flagged as uncertain in Pitfall 8. Must be validated with `zeroclaw skills list` after Phase 1/2 symlink wiring before Phase 3 builds on top of it.
- **`[[model_routes]]` config:** Research confirms the feature exists and route hints are the right abstraction, but the exact TOML syntax for declaring routes was not validated against a live example. Verify against `zeroclaw config schema` before Phase 4 planning.
- **Self-modification approval gate:** OpenClaw had hard PreToolUse hooks to enforce approval gates; ZeroClaw relies on behavioral instructions in AGENTS.md. This is a deliberate architectural tradeoff (less infra, less enforcement). If Kiro bypasses its own AGENTS.md directives during autonomous cron sessions, there is no runtime backstop. Monitor during Phase 3 and enable `[security.otp]` if needed.

## Sources

### Primary (HIGH confidence)
- `/home/hybridz/Projects/zeroclaw/docs/config-reference.md` — ZeroClaw config schema, all sections, defaults, and notes (verified Feb 25 2026)
- `/home/hybridz/Projects/zeroclaw/docs/commands-reference.md` — CLI surface, cron, skills, doctor (verified Feb 25 2026)
- `/etc/nixos/zeroclaw/reference/upstream-docs/operations-runbook.md` — Operational patterns, verified Feb 18 2026
- `/etc/nixos/zeroclaw/module.nix` — Current deployed module, authoritative for what is already configured
- `/etc/nixos/openclaw/summary.md` — First-hand OpenClaw architecture and post-mortem; primary source for feature requirements and pitfall history

### Secondary (HIGH confidence, first-hand)
- `/home/hybridz/.claude/projects/-etc-nixos/memory/MEMORY.md` — Session-learned gotchas: Z.AI API type, phone_number_id quoting
- `/etc/nixos/zeroclaw/.planning/PROJECT.md` — Project constraints and key decisions
- `/etc/nixos/zeroclaw/documents/AGENTS.md`, `TOOLS.md` — Behavioral requirements, capability inventory

### Tertiary (supporting context)
- `/home/hybridz/Projects/zeroclaw/CLAUDE.md` — ZeroClaw engineering principles (why principles exist reveals past pain points)
- `/etc/nixos/openclaw/CLAUDE.md` — Prior OpenClaw architecture reference for migration context

---
*Research completed: 2026-03-04*
*Ready for roadmap: yes*
