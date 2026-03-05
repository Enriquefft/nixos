# Phase 2: Scaffolding and Identity - Research

**Researched:** 2026-03-04
**Domain:** ZeroClaw skills system, cron CLI, identity document format, CLAUDE.md conventions
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Full audit of all 6 identity documents — read every doc end-to-end, rewrite anything that doesn't reflect ZeroClaw's model
- AGENTS.md: full rewrite — replace the entire System-First Rule table and all tool references (cron-manager, skill-scaffold, task-queue, cron-sync, /etc/nixos/openclaw/) with ZeroClaw-native equivalents
- Other 5 docs: surgical where possible, rewrite where needed — fix platform/path references (OpenClaw → ZeroClaw, openclaw paths → zeroclaw paths); rewrite any section that is semantically wrong for ZeroClaw
- Autonomy boundaries stay the same, tooling changes — Kiro retains full autonomy for cron/skills work, using ZeroClaw's native CLI
- No backwards compatibility — drop OpenClaw entirely, no "also works with" stubs or migration notes
- CLAUDE.md audience: both coding agents and Kiro working on its own infrastructure
- CLAUDE.md content: deployment model (rebuild vs live-edit table), file map of every important file/directory, agent operational guide (how Kiro creates skills/cron, how coding agents test changes)
- IPC documentation: deferred to Phase 3 — do not include
- Both READMEs: full operational guides — Kiro must be able to create a new skill or cron job by reading the README alone, with zero human guidance
- No YAML files for cron — cron is SQLite-backed and managed entirely via zeroclaw CLI

### Claude's Discretion
- Section ordering and heading structure within CLAUDE.md
- Exact SKILL.toml field annotations and example values in skills/README.md
- Exact cron job naming conventions in cron/README.md (as long as they're documented)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope. IPC documentation is Phase 3 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| DIR-01 | `skills/` directory exists with scaffolding and a README documenting SKILL.toml conventions | Skills use SKILL.md (frontmatter) or SKILL.toml format; installed to `~/.zeroclaw/workspace/skills/` via `zeroclaw skills install`; no NixOS symlink needed |
| DIR-02 | `cron/` directory exists with structure for cron job definitions and a README documenting conventions | Cron is SQLite-backed at `~/.zeroclaw/workspace/cron/jobs.db`; managed purely via `zeroclaw cron` CLI; no file-based job definitions |
| DIR-03 | CLAUDE.md exists in `/etc/nixos/zeroclaw/` providing comprehensive guidance for any LLM agent | File does not yet exist; must be created at repo root; covers deployment model + file map + operational guide |
| IDN-01 | All 6 identity documents audited and updated to remove stale OpenClaw references | All 6 docs contain OpenClaw references (verified by reading each); specific changes catalogued per document below |
| IDN-02 | Identity document format verified against ZeroClaw's expected schema | `[identity] format = "openclaw"` loads markdown files from `~/.zeroclaw/documents/`; filenames and structure confirmed correct |
| MOD-03 | CLAUDE.md documents which files require rebuild vs live-edit | Deployment model research complete; rebuild-vs-live-edit table documented below |
</phase_requirements>

## Summary

Phase 2 is primarily a documentation and content phase with one binary validation step (skills symlink). All underlying infrastructure from Phase 1 is confirmed working: `zeroclaw skills list` returns 3 skills with no errors, `zeroclaw cron list` shows "No scheduled tasks yet" with no errors, and the identity documents symlink correctly to `~/.zeroclaw/documents/`.

The skills system uses `~/.zeroclaw/workspace/skills/` as its directory — this is automatically created by ZeroClaw and already populated with 2 preloaded skills (`find-skills`, `skill-creator`) plus a test skill. The `/etc/nixos/zeroclaw/skills/` repo directory is for Kiro's authored skills that get deployed via `zeroclaw skills install ./skills/my-skill`. The cron system is entirely SQLite-backed at `~/.zeroclaw/workspace/cron/jobs.db` — no file-based job definitions, no sync command needed.

The identity document audit reveals significant OpenClaw references across all 6 files. IDENTITY.md and SOUL.md have the most critical stale references (wrong platform name, wrong paths, wrong service names, wrong cron workflow). AGENTS.md requires a full rewrite because its System-First Rule table and Task Queue Protocol reference entirely non-existent tools. TOOLS.md has comprehensive OpenClaw path and service name references throughout. USER.md and LORE.md have lighter but specific stale references that need surgical fixes.

**Primary recommendation:** Execute in this order: (1) symlink validation (`zeroclaw skills list` — already confirmed working), (2) AGENTS.md rewrite since it's the most changed, (3) SOUL.md/TOOLS.md rewrites, (4) IDENTITY.md/USER.md/LORE.md surgical fixes, (5) create skills/README.md and cron/README.md, (6) create CLAUDE.md.

## Standard Stack

### Core ZeroClaw CLI (verified from upstream-docs/commands-reference.md, 2026-02-25)

| Command | Purpose | Notes |
|---------|---------|-------|
| `zeroclaw skills list` | List installed skills | Shows name, version, description |
| `zeroclaw skills install <source>` | Install a skill | Source can be local path, git URL, or alias |
| `zeroclaw skills audit <source>` | Audit a skill before installing | Security check |
| `zeroclaw skills remove <name>` | Remove an installed skill | |
| `zeroclaw cron list` | List all cron jobs | Currently shows "No scheduled tasks yet" |
| `zeroclaw cron add <expr> [--tz <TZ>] <command>` | Add a cron job | expr is standard cron expression |
| `zeroclaw cron add-at <rfc3339> <command>` | Add one-time job at timestamp | |
| `zeroclaw cron add-every <ms> <command>` | Add repeating job by interval | |
| `zeroclaw cron once <delay> <command>` | Run once after delay | |
| `zeroclaw cron remove <id>` | Remove a cron job | |
| `zeroclaw cron pause <id>` | Pause a cron job | |
| `zeroclaw cron resume <id>` | Resume a paused job | |

### Skill Format (verified from `~/.zeroclaw/workspace/skills/README.md`)

Two supported formats:

**SKILL.md format (simpler, recommended for Kiro's skills):**
```markdown
---
name: my-skill
description: What this skill does and when to use it
---

# Skill Name

Markdown instructions for the agent.
```

**SKILL.toml format (richer, supports tool registration):**
```toml
[skill]
name = "my-skill"
description = "What this skill does"
version = "0.1.0"
author = "your-name"
tags = ["productivity", "automation"]

[[tools]]
name = "my_tool"
description = "What this tool does"
kind = "shell"
command = "echo hello"
```

Both formats are supported. SKILL.md is simpler and sufficient for knowledge/instruction skills. SKILL.toml is needed when registering custom tools. The `prompts` and `[[tools]]` fields in SKILL.toml are injected into the agent system prompt at runtime.

### Skill Directory Structure (verified from skill-creator/SKILL.md)

```
skills/
└── my-skill/
    ├── SKILL.md          # required — frontmatter + instructions
    ├── scripts/          # optional — executable code
    ├── references/       # optional — docs loaded into context
    └── assets/           # optional — templates, icons
```

Each installed skill also gets a `_meta.json` (auto-generated by `zeroclaw skills install`):
```json
{
  "slug": "find-skills",
  "source": "https://...",
  "version": "preloaded"
}
```

### Cron System (verified from commands-reference.md + live runtime)

- Backend: SQLite at `~/.zeroclaw/workspace/cron/jobs.db`
- Schema: `cron_jobs` table with `id`, `expression`, `command`, `schedule`, `job_type`, `prompt`, `name`
- `cron.enabled` defaults to `true` — no config change needed
- `cron_runs` table tracks execution history; `max_run_history = 50` by default
- Cron expressions: standard 5-field cron (`0 9 * * *` = daily at 9am)
- Timezone: `--tz <IANA_TZ>` flag on `cron add`
- Commands: can be shell commands or `agent -m "prompt"` for AI-run jobs

### Identity Format (verified from module.nix + config-reference.md)

```toml
[identity]
format = "openclaw"
```

This loads markdown files from `~/.zeroclaw/documents/`. The format name `"openclaw"` is the standard identity format regardless of which platform is running — it's a document schema name, not a platform reference. The 6 expected filenames are: IDENTITY.md, SOUL.md, AGENTS.md, TOOLS.md, USER.md, LORE.md. All 6 are confirmed present and symlinked correctly.

## Architecture Patterns

### Recommended Project Structure

```
/etc/nixos/zeroclaw/
├── CLAUDE.md               # Phase 2 deliverable — agent guidance (rebuild vs live-edit)
├── module.nix              # NixOS home-manager module — rebuild required for changes
├── flake.nix               # (in /etc/nixos/) — rebuild required for changes
├── documents/              # Identity docs — LIVE EDIT (mkOutOfStoreSymlink)
│   ├── IDENTITY.md
│   ├── SOUL.md
│   ├── AGENTS.md
│   ├── TOOLS.md
│   ├── USER.md
│   └── LORE.md
├── skills/                 # Skill sources — deploy via zeroclaw CLI, not symlinked
│   └── README.md           # Phase 2 deliverable — operational guide
└── cron/                   # Cron reference dir — DOCUMENTATION ONLY, no files
    └── README.md           # Phase 2 deliverable — cron CLI guide
```

### Deployment Model: Rebuild vs Live-Edit

This is the core content of MOD-03 (CLAUDE.md). Verified from module.nix analysis and Phase 1 work:

| File / Directory | Deployment Model | How to Apply |
|------------------|-----------------|--------------|
| `module.nix` | Rebuild required | `sudo nixos-rebuild switch --flake /etc/nixos#nixos` |
| `flake.nix` | Rebuild required | `direnv reload` then rebuild |
| `documents/*.md` (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) | Live edit | Edit in `/etc/nixos/zeroclaw/documents/`, commit to git — symlink means ZeroClaw sees changes immediately |
| Skills in `~/.zeroclaw/workspace/skills/` | Live — deployed via CLI | `zeroclaw skills install ./skills/my-skill` from `/etc/nixos/zeroclaw/` |
| Cron jobs | Live — managed via CLI | `zeroclaw cron add/remove/pause/resume` |
| `config.toml` | Rebuild required | Config is rendered by Nix at build time |
| Secrets (agenix) | Rebuild required | Secrets rendered by NixOS |

### Skills Workflow Pattern (for skills/README.md)

```
1. Create skill directory in /etc/nixos/zeroclaw/skills/my-skill/
2. Write SKILL.md with YAML frontmatter (name, description) + instructions
3. Audit: zeroclaw skills audit ./skills/my-skill
4. Install: zeroclaw skills install ./skills/my-skill
5. Verify: zeroclaw skills list
6. Commit directory to git
```

Skills installed this way live in `~/.zeroclaw/workspace/skills/` (managed by ZeroClaw). The repo `skills/` dir is the source-of-truth for skill authoring.

### Cron Workflow Pattern (for cron/README.md)

```
# Add a daily AI agent session
zeroclaw cron add '0 9 * * *' --tz 'America/Lima' 'agent -m "Run morning briefing"'

# Add a recurring task every 30 minutes (in ms: 1800000)
zeroclaw cron add-every 1800000 'agent -m "Check task queue"'

# List jobs to get IDs
zeroclaw cron list

# Pause / resume / remove
zeroclaw cron pause <id>
zeroclaw cron resume <id>
zeroclaw cron remove <id>
```

No YAML files. No `cron-sync`. No `jobs.json`. The SQLite DB at `~/.zeroclaw/workspace/cron/jobs.db` is the sole store.

### Anti-Patterns to Avoid

- **YAML cron files**: There are no file-based cron definitions in ZeroClaw. OpenClaw used `cron/jobs/*.yaml` + `cron-sync` — this entire mechanism does not exist in ZeroClaw.
- **Direct DB writes**: Never write to `jobs.db` directly. Only use `zeroclaw cron` CLI.
- **Editing ~/.zeroclaw/ directly**: All source files live in `/etc/nixos/zeroclaw/`. Never edit runtime paths.
- **Using `cron-manager`, `skill-scaffold`, `task-queue`, `cron-sync`**: These are OpenClaw-specific scripts that do not exist in ZeroClaw.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scheduling recurring tasks | Shell scripts + systemd timers + crontab | `zeroclaw cron add` | ZeroClaw's scheduler is SQLite-backed, runs jobs as agent sessions, handles retries |
| Installing/removing skills | Manual file copies | `zeroclaw skills install/remove` | CLI runs security audit, generates `_meta.json`, manages workspace |
| Skill security checking | Manual review | `zeroclaw skills audit` | Static audit checks for symlinks, script injection, prompt injection |

**Key insight:** ZeroClaw's cron and skills systems are purpose-built for AI agent use. The cron `command` field accepts `agent -m "prompt"` which runs a full AI session — not a bare shell command. Don't replicate this with systemd timers.

## Common Pitfalls

### Pitfall 1: `reject_symlink_tools_dir` is for WASM, not native skills

**What goes wrong:** The STATE.md blocker cited `reject_symlink_tools_dir` as a possible issue for the skills directory symlink.
**Why it happens:** The config key sounds general but it is in `[runtime.wasm.security]` — it only applies to the WASM tools directory, not to the native skills system.
**How to avoid:** This is not a concern for Phase 2. The skills directory at `~/.zeroclaw/workspace/skills/` is a real directory, not a symlink. `zeroclaw skills list` is confirmed working (verified live: returns 3 skills).
**Warning signs:** If `zeroclaw skills list` returns an error about symlinks, check if module.nix accidentally creates a symlink at `~/.zeroclaw/workspace/skills/` — but Phase 1 explicitly did NOT wire skills/ or cron/ as symlinks.

### Pitfall 2: Skills audit rejects symlinks inside skill packages

**What goes wrong:** Attempting to include symlinks inside a skill directory (e.g., a `references/` symlink pointing elsewhere) causes `zeroclaw skills install` to reject the skill.
**Why it happens:** The security audit blocks "symlinks inside the skill package" per commands-reference.md.
**How to avoid:** All files inside a skill directory must be regular files. Copy files, don't symlink them. The `mkOutOfStoreSymlink` pattern used for identity docs does NOT apply inside skill packages.
**Warning signs:** `zeroclaw skills audit` reports "symlink rejected" before install attempt.

### Pitfall 3: Identity documents symlink to Nix store, not source

**What goes wrong:** The documents at `~/.zeroclaw/documents/` symlink to the Nix store path (e.g., `/nix/store/8wqrr1n175jjnpb7.../documents/IDENTITY.md`), not directly to `/etc/nixos/zeroclaw/documents/IDENTITY.md`.
**Why it happens:** `mkOutOfStoreSymlink` creates a symlink from HM-managed path to the source path. The HM file itself is a Nix store file that symlinks to source. Two-hop symlink chain.
**How to avoid:** This is normal and expected — edits to `/etc/nixos/zeroclaw/documents/IDENTITY.md` are immediately visible at `~/.zeroclaw/documents/IDENTITY.md` because the Nix store file is just a pass-through symlink. No action needed.

### Pitfall 4: Cron `command` field must be a full shell command or `zeroclaw agent` invocation

**What goes wrong:** Writing `cron add '0 9 * * *' 'morning-briefing'` where `morning-briefing` is not a valid shell command or zeroclaw subcommand.
**Why it happens:** The `command` field is executed as a shell command. Bare names don't work unless they're on PATH.
**How to avoid:** For AI-driven cron sessions: `zeroclaw cron add '0 9 * * *' 'agent -m "Run morning briefing..."'`. For shell automation: `zeroclaw cron add '0 9 * * *' '/run/current-system/sw/bin/bash -c "..."'`.

### Pitfall 5: `cron.enabled` vs `cron add` requiring `cron.enabled = true`

**What goes wrong:** Commands-reference.md says "Mutating schedule/cron actions require `cron.enabled = true`". But `cron.enabled` defaults to `true` per the config schema, so no config change is needed.
**Why it happens:** The docs warn about it, suggesting it can be disabled. It's enabled by default.
**How to avoid:** Confirm `zeroclaw cron list` works (it does). No `[cron]` section needed in config.toml.

## Code Examples

### SKILL.md Example (minimal)
```markdown
---
name: morning-briefing
description: Runs Kiro's morning briefing session — job scan, task queue triage, overnight summary. Use when morning routine needs to run.
---

# Morning Briefing

Check overnight messages, triage task queue, scan for hot job listings.
Report findings to Enrique via WhatsApp.

## Steps

1. Run `zeroclaw cron list` to confirm cron system is healthy
2. Check task queue for items over 24h old
3. Scan job boards for new high-match listings
4. Compose summary and send via kapso-whatsapp-cli
```

### SKILL.toml Example (with tool registration)
```toml
[skill]
name = "job-scanner"
description = "Fetches and filters job listings from configured boards"
version = "0.1.0"
author = "kiro"
tags = ["job-search", "automation"]

[[tools]]
name = "scan_jobs"
description = "Scan job boards for new listings"
kind = "shell"
command = "node /etc/nixos/zeroclaw/skills/job-scanner/run.js"
```

### Cron Add Examples (from commands-reference.md)
```bash
# Daily AI session at 9am Lima time
zeroclaw cron add '0 9 * * *' --tz 'America/Lima' 'agent -m "Run morning briefing"'

# Every 30 minutes (1800000ms)
zeroclaw cron add-every 1800000 'agent -m "Check task queue and process pending items"'

# One-time job at specific timestamp
zeroclaw cron add-at '2026-03-05T09:00:00-05:00' 'agent -m "Follow up on application to Stripe"'

# List jobs
zeroclaw cron list

# Remove by ID
zeroclaw cron remove <id>
```

### Skills Install Workflow
```bash
# From repo root
cd /etc/nixos/zeroclaw

# Create skill
mkdir -p skills/my-skill
# Write skills/my-skill/SKILL.md

# Audit before installing
zeroclaw skills audit ./skills/my-skill

# Install into workspace
zeroclaw skills install ./skills/my-skill

# Verify
zeroclaw skills list

# Commit to git
git add skills/my-skill/
git commit -m "feat(skills): add my-skill"
```

## Identity Document Audit Findings

### IDENTITY.md — Stale References Found

File: `/etc/nixos/zeroclaw/documents/IDENTITY.md`

| Line | Stale Content | Required Fix |
|------|---------------|-------------|
| 9 | "You run 24/7 on Enrique's personal NixOS workstation via **OpenClaw**." | Replace "OpenClaw" with "ZeroClaw" |

No other OpenClaw references. The document is otherwise clean. Surgical fix: 1 line.

### SOUL.md — Stale References Found

File: `/etc/nixos/zeroclaw/documents/SOUL.md`

| Section | Stale Content | Required Fix |
|---------|---------------|-------------|
| System Access | "Before modifying anything inside `/etc/nixos/openclaw/`, read **`/etc/nixos/openclaw/CLAUDE.md`** first." | Replace with `/etc/nixos/zeroclaw/CLAUDE.md` |
| System Access | "OpenClaw config: `/etc/nixos/openclaw`" | Replace with "ZeroClaw config: `/etc/nixos/zeroclaw`" |
| System Access | "Workspace files: `/etc/nixos/openclaw/documents/`" | Replace with `/etc/nixos/zeroclaw/documents/` |
| System Access | "System update: `sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /etc/nixos#nixos`" | Command is correct, no change needed |
| System Access | "Full profile reference: `/etc/nixos/openclaw/reference/full-profile.md`" | Replace with `/etc/nixos/zeroclaw/reference/full-profile.md` (verify file exists or note as TODO) |
| Cron Jobs | Entire "Cron Jobs" section references OpenClaw YAML workflow: `cron/jobs/*.yaml`, `cron-sync`, `openclaw cron list` | Full rewrite: replace with `zeroclaw cron` CLI commands |
| Cron Jobs | `export $(cat /run/secrets/rendered/openclaw.env | xargs)` | Replace with `ZEROCLAW_API_KEY` env var if needed, or remove entirely |

Surgical in personality/voice sections, rewrite in System Access and Cron Jobs sections.

### AGENTS.md — Full Rewrite Required

File: `/etc/nixos/zeroclaw/documents/AGENTS.md`

Stale content spans the entire document:

| Section | Stale Content | Required Fix |
|---------|---------------|-------------|
| System-First Rule table | `cron-manager create`, `skill-scaffold create`, `task-queue add` | Replace with `zeroclaw cron add`, `zeroclaw skills install`, native SQLite memory or file-based tracking |
| System-First Rule table | "NixOS" row references `/etc/nixos/openclaw/CLAUDE.md` | Update to `/etc/nixos/zeroclaw/CLAUDE.md` |
| "Never ask, just do" list | "Managing cron jobs (edit YAML in `/etc/nixos/openclaw/cron/jobs/`, run `cron-sync`)" | Replace with "Managing cron jobs (use `zeroclaw cron add/remove/pause/resume`)" |
| "Never ask, just do" | "Updating your own config and documents (read `/etc/nixos/openclaw/CLAUDE.md` first)" | Update path |
| Hard Limits | "Never create cron jobs outside `/etc/nixos/openclaw/cron/jobs/*.yaml` + `cron-sync`..." | Replace with: Never create cron jobs via files/scripts — use `zeroclaw cron` CLI only |
| Self-Repair Protocol | References `task-queue add`, `task-queue resolve`, `/etc/nixos/openclaw/CLAUDE.md` | Redesign: no task-queue tool; use ZeroClaw memory or a custom skill for issue tracking |
| Task Queue Protocol | Entire section references `task-queue` skill | Remove or redesign for ZeroClaw-native equivalent |
| Self-Repair quick reference | `task-queue add/list/next/resolve/stats` commands | Remove — these commands don't exist |

The "Core Directive", "Approval Gate", "Priority Stack", "Hard Limits" (non-cron items), "Handling Uncertainty", "Proactive Triggers", "Error Handling" sections are semantically correct and need only path/tool name updates.

### TOOLS.md — Stale References Found

File: `/etc/nixos/zeroclaw/documents/TOOLS.md`

| Section | Stale Content | Required Fix |
|---------|---------------|-------------|
| Claude Code — Self-repair | "fix broken/stubbed skills in `/etc/nixos/openclaw/skills/`" | Replace with `/etc/nixos/zeroclaw/skills/` |
| File System | "/etc/nixos/openclaw/ - Your own configuration" | Replace with `/etc/nixos/zeroclaw/` |
| File System | "/etc/nixos/openclaw/documents/ - Your identity and behavior files" | Replace with `/etc/nixos/zeroclaw/documents/` |
| systemctl — Key services | "openclaw-gateway, kapso-whatsapp-bridge" | Replace with "zeroclaw-gateway, kapso-whatsapp-bridge" |
| journalctl | "journalctl --user -u openclaw-gateway -f" | Replace with "zeroclaw-gateway" |
| Self-Modification | "Before making any changes inside `/etc/nixos/openclaw/`" and CLAUDE.md path | Update all paths to zeroclaw |
| Self-Modification | "Edit files in `/etc/nixos/openclaw/documents/`..." then "Run `up` to apply" | Replace `up` with: document-only changes take effect immediately via symlink, no rebuild needed |
| Cron Management | Entire section — references `cron-manager`, YAML workflow, OpenClaw paths | Full rewrite using `zeroclaw cron` CLI commands |
| Utility Skills table | Lists `cron-manager`, `skill-scaffold`, `job-scanner`, `rss-reader`, `job-tracker`, `git-activity`, `task-queue` | These are OpenClaw skills. Replace section header to reflect current state: only `find-skills` and `skill-creator` are preloaded; others are v2 scope |
| Utility Skills — state files | "State files: `~/.local/state/openclaw-cron/<skill-name>/`" | Remove or update |

### USER.md — Stale References Found

File: `/etc/nixos/zeroclaw/documents/USER.md`

| Line | Stale Content | Required Fix |
|------|---------------|-------------|
| Full Profile | "The complete detailed profile lives at `/etc/nixos/openclaw/reference/full-profile.md`." | Replace with `/etc/nixos/zeroclaw/reference/full-profile.md` (verify file exists) |

Minor: 1 path reference. Rest of document is personal data with no platform references.

### LORE.md — Stale References Found

File: `/etc/nixos/zeroclaw/documents/LORE.md`

| Section | Stale Content | Required Fix |
|---------|---------------|-------------|
| Resume/CV Notes | "When drafting cover letters, pull from `/etc/nixos/openclaw/reference/full-profile.md`" | Replace path |
| Resume/CV Notes | "For polished, ready-to-adapt responses by question type, read `/etc/nixos/openclaw/reference/reusable-responses.md`" | Replace path |
| Application Tracker | "Maintained at `~/openclaw-data/job-tracker.json`" | Update to `~/zeroclaw-data/job-tracker.json` or remove (task-queue concept is gone) |
| Freelance Tracker | "Same location: `~/openclaw-data/freelance-tracker.json`" | Update path |
| Products — OpenClaw | "OpenClaw + Nix Automation (Kiro)" and "This system (Kiro) is the product" | Rename to "ZeroClaw + Nix Automation (Kiro)" |
| Products — Kapso bridge | "OpenClaw Kapso WhatsApp Bridge" | Rename to "Kapso WhatsApp Bridge" (it's now a standalone project) |
| Distribution — Narrative | "automating his entire job search and content pipeline with OpenClaw on NixOS" | Replace "OpenClaw" with "ZeroClaw" |
| Key Stories | "Reference `/etc/nixos/openclaw/reference/full-profile.md`" | Replace path |

Also note: USER.md references "Key Differentiators" #7: "Open-source contributor. OpenClaw Kapso bridge, 100 stars." — The bridge is now a separate project from ZeroClaw. This remains factually accurate as a personal achievement; no change needed unless Enrique's framing has changed.

## Symlink Validation Status

**Blocker from STATE.md: RESOLVED.**

Live test results:
- `zeroclaw skills list` — WORKING. Returns 3 skills: `test-skill`, `find-skills`, `skill-creator`. No symlink errors.
- `zeroclaw cron list` — WORKING. Returns "No scheduled tasks yet." with no errors.

The `reject_symlink_tools_dir` concern was misidentified in the original STATE.md. This config key is in `[runtime.wasm.security]` and applies only to the WASM tools directory, not to the native skills system. The skills directory at `~/.zeroclaw/workspace/skills/` is a real directory (not a symlink) created and managed by ZeroClaw itself.

The symlink audit flag that DOES apply to skills: the security audit rejects **symlinks inside skill packages** (files within the skill directory being symlinks), not the skills directory itself being a symlink.

**No module.nix redesign needed.** The Phase 1 decision to NOT symlink skills/ or cron/ was correct. Skills are deployed via `zeroclaw skills install`, cron is managed via CLI.

## CLAUDE.md Content Map

The planner will create CLAUDE.md from scratch. Required sections (per decisions):

1. **Deployment Model** — rebuild vs live-edit table (see Architecture Patterns above)
2. **File Map** — every important file/directory, one-liner purpose each
3. **Agent Operational Guide** — how Kiro creates skills (CLI workflow), how Kiro manages cron (CLI workflow), how coding agents test changes (nix flake check, nix build, nixos-rebuild)
4. **Do NOT include** — IPC documentation (Phase 3 scope)

Intended audience: coding agents AND Kiro. Must be self-contained — an agent that has never seen this repo should understand the full deployment model from reading CLAUDE.md once.

## State of the Art

| OpenClaw Pattern | ZeroClaw Pattern | Impact |
|-----------------|-----------------|--------|
| `cron-manager create` + YAML files + `cron-sync` | `zeroclaw cron add <expr> <command>` | No files, no sync — single CLI command |
| `skill-scaffold create` + TypeScript `run.ts` | `zeroclaw skills install ./path/to/skill` | No scaffold script — just a directory with SKILL.md |
| `task-queue add/list/resolve` | No built-in equivalent (v2 scope: CRN-01) | Task tracking is not yet native; use memory or a custom skill |
| `openclaw cron list` | `zeroclaw cron list` | Direct CLI replacement |
| YAML cron job definitions | CLI-only, SQLite-backed | More robust, no file sync required |
| OpenClaw skills at `/etc/nixos/openclaw/skills/` | ZeroClaw skills at `/etc/nixos/zeroclaw/skills/` (source), `~/.zeroclaw/workspace/skills/` (installed) | Two-directory model: source in git, installed in workspace |

**Deprecated/outdated:**
- `cron-sync`: Does not exist in ZeroClaw
- `skill-scaffold`: Does not exist in ZeroClaw
- `task-queue`: Does not exist in ZeroClaw (CRN-01 is v2 scope)
- `cron-manager`: Does not exist in ZeroClaw
- YAML cron files: Not used in ZeroClaw

## Open Questions

1. **`full-profile.md` and `reusable-responses.md` existence**
   - What we know: USER.md and LORE.md reference these at `/etc/nixos/openclaw/reference/`
   - What's unclear: Whether these files were migrated to `/etc/nixos/zeroclaw/reference/` in Phase 1
   - Recommendation: Planner should include a task to check existence and update paths; if files don't exist, update references to note they're not yet available

2. **Task queue replacement in AGENTS.md**
   - What we know: The entire Task Queue Protocol in AGENTS.md references `task-queue` skill which doesn't exist in ZeroClaw
   - What's unclear: What lightweight replacement to document for Phase 2 (CRN-01 is v2 scope)
   - Recommendation: In AGENTS.md rewrite, replace the Task Queue Protocol with ZeroClaw memory (`memory_store`/`memory_recall`) for durable tracking, noting that a dedicated skill will be built in v2

3. **Cron job storage after `cron add`**
   - What we know: Jobs store in SQLite at `~/.zeroclaw/workspace/cron/jobs.db`
   - What's unclear: Whether `cron/README.md` should document the SQLite schema for power users
   - Recommendation: Include a brief schema note in cron/README.md for transparency; don't document internal IDs in detail

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual CLI validation (no automated test framework for documentation) |
| Config file | none — validation is live ZeroClaw CLI |
| Quick run command | `zeroclaw skills list && zeroclaw cron list && zeroclaw doctor` |
| Full suite command | `zeroclaw doctor && zeroclaw skills list && zeroclaw agent -m "hello" --one-shot` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIR-01 | `skills/README.md` exists and zeroclaw can list skills | smoke | `zeroclaw skills list` | ❌ Wave 0 |
| DIR-02 | `cron/README.md` exists and zeroclaw cron works | smoke | `zeroclaw cron list` | ❌ Wave 0 |
| DIR-03 | CLAUDE.md exists at repo root | smoke | `test -f /etc/nixos/zeroclaw/CLAUDE.md && echo PASS` | ❌ Wave 0 |
| IDN-01 | No "openclaw" string in identity docs | unit | `grep -ri "openclaw" /etc/nixos/zeroclaw/documents/ && echo FAIL \|\| echo PASS` | ❌ Wave 0 |
| IDN-02 | Identity docs load when ZeroClaw starts | smoke | `zeroclaw doctor 2>&1 \| grep -i "identity\|document"` | ❌ Wave 0 |
| MOD-03 | CLAUDE.md contains rebuild vs live-edit table | manual | Read CLAUDE.md and verify table presence | manual-only |

### Sampling Rate

- **Per task commit:** `zeroclaw skills list && zeroclaw cron list`
- **Per wave merge:** `zeroclaw doctor && grep -ri "openclaw" /etc/nixos/zeroclaw/documents/ && echo "Audit: PASS" || echo "Audit: FAIL - openclaw refs remain"`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `skills/README.md` — covers DIR-01
- [ ] `cron/README.md` — covers DIR-02
- [ ] `CLAUDE.md` — covers DIR-03 and MOD-03
- [ ] OpenClaw audit grep command — covers IDN-01 (command is a one-liner, no file needed)
- No framework install needed — using ZeroClaw CLI + grep

## Sources

### Primary (HIGH confidence)
- `/etc/nixos/zeroclaw/reference/upstream-docs/commands-reference.md` (2026-02-25) — all zeroclaw CLI commands
- `/etc/nixos/zeroclaw/reference/upstream-docs/config-reference.md` (2026-02-25) — `[cron]`, `[skills]`, `[identity]`, `[runtime.wasm.security]` sections
- `~/.zeroclaw/workspace/skills/README.md` — SKILL.md and SKILL.toml format (from live ZeroClaw workspace)
- `/home/hybridz/Projects/zeroclaw/skills/skill-creator/SKILL.md` — canonical skill structure and anatomy
- Live CLI tests: `zeroclaw skills list`, `zeroclaw cron list`, `zeroclaw config schema` (2026-03-04)

### Secondary (MEDIUM confidence)
- Module.nix analysis — deployment model and symlink chain verified by reading actual file
- `~/.zeroclaw/` directory structure — workspace layout verified by `ls` commands
- `~/.zeroclaw/workspace/cron/jobs.db` — schema verified via `strings` inspection

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- ZeroClaw CLI commands: HIGH — verified from upstream-docs (2026-02-25) and live CLI tests
- SKILL format: HIGH — verified from live workspace README and skill-creator canonical doc
- Cron system: HIGH — verified from commands-reference + live CLI + schema extraction
- Identity audit findings: HIGH — read all 6 documents and catalogued specific stale content
- `reject_symlink_tools_dir` clarification: HIGH — verified from config-reference.md that this is WASM-only

**Research date:** 2026-03-04
**Valid until:** 2026-04-04 (stable APIs, but verify against live binary if ZeroClaw updates)
