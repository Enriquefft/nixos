# Phase 2: Scaffolding and Identity - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the structural layer Kiro reads at runtime: create skills/ and cron/ directories with full operational READMEs, write CLAUDE.md for any agent working on this repo, and audit all 6 identity documents to remove stale OpenClaw references and reflect ZeroClaw's actual model. No backwards compatibility, no migration stubs — clean break from OpenClaw.

</domain>

<decisions>
## Implementation Decisions

### Identity document audit
- **Full audit of all 6 documents** — read every doc end-to-end, rewrite anything that doesn't reflect ZeroClaw's model
- **AGENTS.md: full rewrite** — replace the entire System-First Rule table and all tool references (cron-manager, skill-scaffold, task-queue, cron-sync, /etc/nixos/openclaw/) with ZeroClaw-native equivalents
- **Other 5 docs: surgical where possible, rewrite where needed** — fix platform/path references (OpenClaw → ZeroClaw, openclaw paths → zeroclaw paths); rewrite any section that is semantically wrong for ZeroClaw
- **Autonomy boundaries stay the same, tooling changes** — Kiro retains full autonomy for cron/skills work, just using ZeroClaw's native CLI instead of OpenClaw's custom tools
- **No backwards compatibility** — drop OpenClaw entirely, no "also works with" stubs or migration notes

### CLAUDE.md scope
- **Audience:** Both coding agents (Claude Code, etc.) and Kiro working on its own infrastructure
- **Content for Phase 2:** Deployment model (rebuild vs live-edit table), file map of every important file/directory, and agent operational guide (how Kiro creates skills/cron, how coding agents test changes)
- **IPC documentation: deferred to Phase 3** — IPC-03 is Phase 3 scope, don't reach ahead
- **Phase 3 will expand** — self-modification workflow, self-repair protocol, and multi-agent IPC docs added in Phase 3

### skills/cron READMEs
- **Both READMEs: full operational guides** — Kiro must be able to create a new skill or cron job by reading the README alone, with zero human guidance
- **skills/README.md:** annotated SKILL.toml example with all key fields, directory structure convention, and exact steps to create/register/test a skill using ZeroClaw's CLI
- **cron/README.md:** ZeroClaw cron CLI coverage (SQLite-backed, not YAML files), job definition format, how to add/list/remove jobs, project naming and scheduling conventions
- **Researcher must look up actual ZeroClaw CLI commands** from reference/upstream-docs/ — researcher does not need to guess

### Symlink validation
- **Phase 2 plan includes validation step + contingency** — run `zeroclaw skills list`, if skills symlink is blocked by `reject_symlink_tools_dir`, redesign module.nix wiring before Phase 3 depends on it
- Resolves the open blocker in STATE.md

### Claude's Discretion
- Section ordering and heading structure within CLAUDE.md
- Exact SKILL.toml field annotations and example values in skills/README.md
- Exact cron job naming conventions in cron/README.md (as long as they're documented)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `documents/` directory: all 6 identity files already exist (IDENTITY.md, SOUL.md, AGENTS.md, TOOLS.md, USER.md, LORE.md) — audit and update in place, don't recreate
- `reference/upstream-docs/`: symlinked to ~/Projects/zeroclaw/docs — researcher can read ZeroClaw CLI and SKILL.toml docs from here
- `module.nix`: already wires `documents/` via mkOutOfStoreSymlink; skills/ and cron/ wiring is already in place (from Phase 1)

### Established Patterns
- Live-editable files use `mkOutOfStoreSymlink` — identity docs, skills, cron all fall in this category
- Git-first: all edits go in /etc/nixos/zeroclaw/, committed to git, never edited at ~/.zeroclaw/ directly
- CLAUDE.md is read from the repo directly by agents — no symlink needed, not a ~/.zeroclaw/ runtime file

### Integration Points
- CLAUDE.md lives at `/etc/nixos/zeroclaw/CLAUDE.md` — root of the repo, coding agents find it automatically
- skills/ and cron/ READMEs live inside their respective directories
- Identity docs updated in-place in `documents/` — symlink to ~/.zeroclaw/documents/ already active

</code_context>

<specifics>
## Specific Ideas

- Clean break from OpenClaw — no stubs, no "this replaces X", just write for ZeroClaw as the only system
- AGENTS.md System-First Rule table should reference ZeroClaw's actual CLI (zeroclaw cron, zeroclaw skills, etc.) — researcher should verify exact commands from upstream-docs
- CLAUDE.md should work as a standalone reference — an agent that has never seen this repo should understand the full deployment model from reading CLAUDE.md once

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-scaffolding-and-identity*
*Context gathered: 2026-03-04*
