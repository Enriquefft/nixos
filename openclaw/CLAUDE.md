# OpenClaw Agent Configuration

This directory is the personal OpenClaw agent configuration sub-flake.
Agents working on OpenClaw settings can `cd /etc/nixos/openclaw/` and work here
without needing NixOS context.

## Who works here

Multiple coding agents edit this repo: **Claude Code** (primary), **OpenClaw/Kiro**
(self-modification), and occasionally others (opencode, copilot). This CLAUDE.md is the
canonical context source for all of them.

## Key Files

| File | Purpose |
|------|---------|
| `module.nix` | Gateway config, model providers (ZAI), agent defaults, skill symlinks |
| `documents/` | **OpenClaw agent identity** (Kiro's brain) — NOT repo docs (see below) |
| `skills/` | Utility CLI tools as OpenClaw skills (Bun/TS) |
| `cron/` | Version-controlled cron job definitions |
| `flake.nix` | Sub-flake inputs (nixpkgs, nix-openclaw, kapso-whatsapp-plugin) |
| `reference/` | Reusable content: full profile, application response templates |

## documents/ — OpenClaw identity (NOT repo docs)

The `documents/` directory contains **Kiro's personality, directives, and operational
context** — the files that define how the OpenClaw agent behaves. They are symlinked
into OpenClaw's runtime workspace.

| File | Purpose |
|------|---------|
| `IDENTITY.md` | Who Kiro is (chief of staff, 24/7, WhatsApp) |
| `SOUL.md` | Personality, communication style, system access rules |
| `AGENTS.md` | Operational directives, approval gates, priority stack |
| `TOOLS.md` | Available tools and capabilities inventory |
| `USER.md` | Enrique's profile summary |
| `LORE.md` | Strategy, job search, distribution, research context |
| `PROMPTING-EXAMPLES.md` | Behavior pattern examples |

**Do not confuse these with repo documentation.** Editing these files changes how Kiro
thinks and acts, not how coding agents understand this repo.

## Cron System

YAML-defined jobs synced via `cron-sync`. No rebuild needed — edit YAML, run `cron-sync`.
See **[cron/README.md](cron/README.md)** for schema, workflow, and sync details.

Quick reference: `cron-sync --dry-run` to preview, `cron-sync` to apply.

## Skills

Bun/TS CLI tools symlinked via `mkOutOfStoreSymlink` — live edits, no rebuild.
See **[skills/README.md](skills/README.md)** for structure, CLI contract, and inventory.

## Secrets

Secrets are NOT here. They are injected at runtime from `/run/secrets/rendered/openclaw.env`
by the NixOS machine config (`home-manager/home.nix` + `modules/services/openclaw-secrets.nix`).

Environment variables available at runtime:
- `OPENCLAW_TOKEN` — gateway auth token
- `ZAI_API_KEY` — Z.AI API key
- `KAPSO_API_KEY` — Kapso API key
- `KAPSO_PHONE_NUMBER_ID` — WhatsApp phone number ID

## Testing

```bash
# Validate sub-flake syntax
nix flake check

# Full system build (from /etc/nixos)
nixos-rebuild test --flake /etc/nixos#nixos
# or simply
up

# Check services after rebuild
systemctl --user status openclaw-gateway kapso-whatsapp-bridge

# Cron verification
cron-sync --dry-run
export $(cat /run/secrets/rendered/openclaw.env | xargs) && openclaw cron list
```

## Document-only changes

Editing files in `documents/` (AGENTS.md, SOUL.md, TOOLS.md, etc.) only requires
`up` to activate — no Go rebuild is triggered, just a symlink update.

## What goes where

| Location | Contains | Updated by |
|----------|----------|------------|
| `CLAUDE.md` (this file) | Stable repo structure, build commands, conventions | Coding agents when structure changes |
| `documents/` | OpenClaw agent identity (Kiro's brain) | Kiro (self-modification) or manual edits |
| `memory/MEMORY.md` | Session-learned gotchas only | Claude Code auto-memory |
| `TODO.md` | Improvement backlog | Manual |

## Doc maintenance convention

When you modify the structure of this sub-flake — add/remove skills, change module.nix
schema, update cron workflow, add new directories — **update this CLAUDE.md** to reflect
the change. This file is the single source of truth for coding agents.

Do NOT duplicate stable information into memory files. If something is true across
sessions, it belongs here in CLAUDE.md, not in memory.
