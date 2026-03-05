# ZeroClaw Infrastructure

## What This Is

A version-controlled infrastructure for ZeroClaw — an autonomous AI agent runtime ("Kiro") that serves as a personal chief of staff. Everything lives in `/etc/nixos/zeroclaw/` as the single source of truth, deployed to `~/.zeroclaw/` via NixOS home-manager. Identity documents and skills are symlinked for live editing; config and module changes require a NixOS rebuild. Kiro is fully operational: self-modifying, self-repairing, and autonomously monitoring for unresolved issues every 2 hours.

## Core Value

A robust, extensible foundation that enables Kiro to grow and self-modify without friction — editing identity, creating skills, adding cron jobs, and refining config — all version-controlled, all without unnecessary rebuilds.

## Requirements

### Validated

- ✓ Complete config.toml covering all ZeroClaw sections (autonomy, memory, observability, agent, IPC) — v1.0
- ✓ Proper directory structure with scaffolding for skills/, cron/, conventions documented — v1.0
- ✓ Comprehensive CLAUDE.md optimized for LLM coding agents working on this infrastructure — v1.0
- ✓ module.nix wires all config sections, symlinks live-editable paths via home.activation — v1.0
- ✓ Self-modification paths: Kiro can edit docs, create skills, modify config, add cron — all git-first — v1.0
- ✓ No-rebuild workflow for common changes (identity docs, skills) via home.activation symlinks — v1.0
- ✓ Rebuild-required workflow clearly documented for .nix and structural config changes — v1.0
- ✓ Upstream ZeroClaw docs accessible via symlink — v1.0
- ✓ Self-repair mandate: unconditional, files durable records, sentinel enforces every 2h — v1.0
- ✓ Multi-Agent IPC configured and documented — v1.0

### Active

(None — v1.0 delivered all planned requirements. Next milestone defined via `/gsd:new-milestone`.)

### Out of Scope

- Migrating the 13 OpenClaw cron jobs — infrastructure first, jobs come later
- Specific skills implementation beyond repair-loop and sentinel — scaffolding only
- OpenClaw compatibility — clean break achieved
- Hardware/peripheral config — not relevant

## Context

- **Platform:** ZeroClaw is a Rust-based autonomous agent runtime with native support for cron, skills (SKILL.toml manifests), sub-agent delegation, model routing, memory, autonomy controls, and multi-channel communication
- **Shipped v1.0:** 4 phases, 10 plans, 72 commits, 2,416 LOC across .nix/.md/.toml, built in 1 day
- **Deployment model:** NixOS flake → home-manager module → systemd user service. Config rendered at build time via `pkgs.writeText`; identity docs and skills symlinked via `home.activation` for live editing
- **Communication:** WhatsApp via Kapso bridge, CLI for direct interaction
- **Model providers:** Z.AI (zai, zai-coding) with GLM models; Anthropic available
- **Upstream docs:** Symlinked at `reference/upstream-docs/` → `~/Projects/zeroclaw/docs/`
- **Source of truth:** `/etc/nixos/zeroclaw/` is canonical. `~/.zeroclaw/` is a deployment target, never edited directly
- **Known quirk:** `memory_store` requires explicit user approval in interactive ZeroClaw sessions; cron-triggered sessions (sentinel) are unaffected

## Constraints

- **NixOS deployment:** All structural changes require `sudo nixos-rebuild switch`. Minimize rebuild frequency by symlinking mutable content
- **Git-first edits:** Kiro makes changes in `/etc/nixos/zeroclaw/`, commits to git. No ad-hoc runtime modifications outside version control
- **Single source of truth:** `/etc/nixos/zeroclaw/` is canonical. `~/.zeroclaw/` is a deployment target, never edited directly
- **Z.AI provider:** Uses `chat_completions` wire API only (NOT `openai-responses` — returns 404)
- **Skills:** `.sh` files cannot be placed inside skill packages (rejected by `zeroclaw skills audit`); use `bin/<script>.sh` with absolute path in SKILL.toml

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Replace OpenClaw entirely (not migrate) | ZeroClaw is fundamentally different — native cron, skills, autonomy. Porting OpenClaw's custom infra would fight ZeroClaw's design | ✓ Good — clean foundation, no legacy debt |
| `home.activation` for symlinks (not `mkOutOfStoreSymlink`) | `mkOutOfStoreSymlink` caused multi-hop symlink issues; `home.activation` creates direct 1-hop symlinks | ✓ Good — documents/ live-editable reliably |
| Upstream docs via symlink | Keeps reference current with `git pull`, zero duplication, any agent can read ZeroClaw docs | ✓ Good — reference/upstream-docs/ works |
| Git-first self-modification | All Kiro changes go through git in `/etc/nixos/zeroclaw/`. Ensures auditability, rollback, version control | ✓ Good — MOD-04 verified end-to-end |
| Infrastructure before jobs | Build the foundation right, then incrementally add cron jobs and skills on solid ground | ✓ Good — sentinel + repair-loop shipped clean |
| `memory_recall("issue:")` prefix scan for sentinel | Sentinel scans all keys starting with `issue:` to find unresolved items | ✓ Good — confirmed working in live session |
| `bin/` directory for skill scripts | `.sh` files rejected inside skill packages; absolute path in SKILL.toml sidesteps audit restriction | ✓ Good — repair-loop.sh pattern established |
| `max_actions_per_hour = 9999` | No practical limit needed for Kiro's use case | ✓ Good — unblocks cron execution |

---
*Last updated: 2026-03-05 after v1.0 milestone*
