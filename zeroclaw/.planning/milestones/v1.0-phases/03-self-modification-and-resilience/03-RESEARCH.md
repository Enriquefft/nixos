# Phase 3: Self-Modification and Resilience - Research

**Researched:** 2026-03-04
**Domain:** ZeroClaw agent behavioral documentation, SKILL.toml authoring, cron scheduling, IPC configuration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Self-modification autonomy boundaries (MOD-01)**
All four change types are fully autonomous — no approval required for any:

| Change type | Autonomy level |
|-------------|----------------|
| Identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) | Fully autonomous |
| config.toml (autonomy level, allowed_commands, agent limits, memory settings) | Fully autonomous |
| Skills (create, audit, install via zeroclaw CLI) | Fully autonomous |
| module.nix and other .nix files (requires nixos-rebuild) | Fully autonomous |

**Self-repair mandate scope (RPR-01/02/03)**
- Strengthen existing Self-Repair Protocol in AGENTS.md — expand scope from "internal tool, skill, or config" to "any issue Kiro caused or can fix"
- ZeroClaw runtime crashes: Kiro attempts `systemctl --user restart zeroclaw` once, then reports to Enrique if it stays down
- Broader system issues (failed nixos-rebuild, broken system service): if Kiro caused it, Kiro fixes it; if pre-existing, report and wait
- Move self-repair from "protocol" section to Hard Limits framing — filing before attempting is non-negotiable, not a suggestion
- Unfixable issues: file durable record → attempt workaround → report to Enrique with what was tried and what's needed
- RPR-03 (durable records before repair): already implemented via memory_store Step 1 — strengthen, don't replace

**repair-loop skill**
- Create `repair-loop` skill as SKILL.toml with a callable shell tool
- Tool signature: `repair-loop <issue_description>` — atomically calls `memory_store` to file the record (Step 1 is enforced by the tool, not just docs)
- Makes the behavior invocable by name — harder to skip than prose in AGENTS.md
- Phase 3 creates this skill and installs it

**Error sentinel**
- A cron-based enforcement mechanism that doesn't rely on Kiro's in-session compliance
- Scan strategy: Query ZeroClaw memory for issue records without a `:resolved` counterpart (`memory_recall("issue:")`, filter unresolved)
- Frequency: Every 2 hours
- On unresolved issue found: Run repair-loop for each outstanding issue
- On repair failure: Notify Enrique immediately via WhatsApp — "repair-loop ran for [issue], failed: [what was tried]. Your input needed."
- Phase 3 creates: a `sentinel` skill + adds the sentinel cron job via `zeroclaw cron add`

**MOD-04 end-to-end test**
- Real execution (not docs-only validation)
- Test document: `documents/TEST.md` — created specifically for the test, not a real identity doc
- Manual step: plan documents the test command, Enrique runs it after reviewing the plan
  - Command: `zeroclaw agent -m "Create documents/TEST.md with a timestamped test entry, commit it to git in /etc/nixos/zeroclaw, and confirm the commit with git log"`
- Cleanup: same plan task deletes TEST.md and commits the deletion — leaves no trace
- Verification: `git log` shows two commits (create + delete TEST.md) from the Kiro session

**IPC documentation (CLAUDE.md)**
- Scope: config reference + concept explanation — not a full operational guide
- Content: explain how agents_ipc works (shared db_path at `~/.zeroclaw/agents.db`, staleness_secs, how agents register/discover each other)
- Second instance uses the SAME db_path as Kiro — shared state, agents see each other
- Focus on the mechanism (how IPC works) not a specific use case
- Enough for an agent to configure a second instance without further guidance

### Claude's Discretion

- Exact shell script implementation for repair-loop tool command
- Exact sentinel skill implementation (how memory query is structured)
- SKILL.toml field structure for both skills
- Section ordering and heading style in AGENTS.md additions
- IPC section placement and heading in CLAUDE.md

### Deferred Ideas (OUT OF SCOPE)

- Error-sentinel-v2 using zeroclaw doctor traces: a future sentinel-v2 could scan `zeroclaw doctor traces --event tool_call_result --contains "error"` to catch untracked errors. Not in Phase 3.
- ZeroClaw hooks feature request: Pre/post-tool hooks for true preventive enforcement. Worth filing upstream but not in Phase 3.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MOD-01 | AGENTS.md contains git-first self-modification workflow with explicit autonomy table — no ambiguous cases | AGENTS.md current Self-Modification content is implicit; Phase 3 adds an explicit policy table. Documented below under Architecture Patterns. |
| MOD-04 | Kiro edits `documents/TEST.md`, commits via git, confirms with `git log` — live end-to-end test | Deployment model confirmed: documents/ are mkOutOfStoreSymlink, git-tracked, ZeroClaw reads immediately. git workflow is standard. |
| RPR-01 | AGENTS.md self-repair covers any issue Kiro caused or can fix — not just internal tools | Existing Self-Repair Protocol targets "internal tool, skill, or config" — scope must be broadened and elevated to Hard Limits. |
| RPR-02 | Self-repair mandate is unconditional — config, runtime, and infrastructure problems included | Existing protocol is positioned as a suggestion in a named section. Phase 3 moves it to Hard Limits with explicit ZeroClaw restart command. |
| RPR-03 | All discovered issues filed as durable records before repair attempt | `memory_store("issue:<timestamp>", ...)` pattern already established. repair-loop skill enforces this atomically at the tool level. |
| IPC-03 | CLAUDE.md documents how additional ZeroClaw agent instances communicate with Kiro via IPC | `[agents_ipc]` config section documented in upstream config-reference.md. Three keys confirmed: `enabled`, `db_path`, `staleness_secs`. Four IPC tools documented below. |
</phase_requirements>

---

## Summary

Phase 3 is a behavioral constitution + enforcement infrastructure phase. No new NixOS configuration or module.nix changes are required — all work is document editing, skill creation, cron registration, and a live manual test. The phase has three distinct areas of work: (1) AGENTS.md policy additions for MOD-01 and RPR-01/02/03, (2) two new skills (repair-loop and sentinel) plus a sentinel cron job, and (3) IPC documentation in CLAUDE.md for IPC-03.

The critical architectural insight from CONTEXT.md is that documentation alone is insufficient enforcement — it failed in OpenClaw. Phase 3 addresses this by making the repair behavior invocable at the tool level (repair-loop SKILL.toml), and by adding a cron-based sentinel that runs independently of Kiro's in-session compliance. The sentinel is reactive enforcement (post-hoc), not preventive, and it operates on the existing `memory_store("issue:<timestamp>", ...)` pattern already established in AGENTS.md.

All deliverables in this phase are live-edit (no NixOS rebuild required): documents/ changes take effect immediately via symlink, skills deploy via `zeroclaw skills audit` + `zeroclaw skills install`, and the sentinel cron job is added via `zeroclaw cron add`. The only exception is MOD-04, which is a manual test step — Enrique runs the documented command to trigger a live Kiro session that creates, commits, and deletes `documents/TEST.md`.

**Primary recommendation:** Deliver in four sequential plan files: (1) AGENTS.md policy additions, (2) repair-loop skill, (3) sentinel skill + cron job, (4) IPC documentation in CLAUDE.md + MOD-04 test documentation.

---

## Standard Stack

### Core

| Component | Version/Location | Purpose | Why Standard |
|-----------|-----------------|---------|--------------|
| AGENTS.md | `/etc/nixos/zeroclaw/documents/AGENTS.md` | Kiro's behavioral rules, autonomy gates, repair protocol | Primary identity doc for agent behavior — already established in Phase 2 |
| SKILL.toml | skills/README.md spec | Register callable shell tools | Required format for skills that expose tools the agent can invoke by name |
| SKILL.md | skills/README.md spec | Knowledge/instruction injection into agent context | Required format for skills that teach behavior rather than expose tools |
| `zeroclaw cron add` | CLI | Add sentinel cron job to SQLite scheduler | Only cron method in ZeroClaw — no files, no YAML |
| `memory_store` / `memory_recall` | ZeroClaw built-in tool | Durable issue tracking across sessions | Established pattern in AGENTS.md — Phase 3 builds on it |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `zeroclaw skills audit` | Security check before install | Always before `zeroclaw skills install` |
| `zeroclaw skills install` | Deploy skill to workspace | After audit passes |
| `systemctl --user restart zeroclaw` | ZeroClaw runtime restart | Prescribed command for runtime crash repair in RPR-02 |
| `git commit` + `git log` | MOD-04 test verification | Kiro's git-first self-modification workflow |
| `zeroclaw doctor traces` | (Future sentinel-v2 only — deferred) | Not in Phase 3 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SKILL.toml for repair-loop | SKILL.md prose only | SKILL.md relies on Kiro choosing to follow instructions; SKILL.toml makes repair_loop a named callable tool Kiro invokes explicitly — harder to skip |
| SKILL.md for sentinel | Cron + SKILL.toml | Sentinel needs agent context to query memory and run repair-loop; SKILL.md instructions plus a cron `agent -m` command is the correct ZeroClaw pattern |
| WhatsApp immediate notification | EOD summary | CONTEXT.md explicitly requires immediate WhatsApp notification on repair failure — not EOD |

---

## Architecture Patterns

### AGENTS.md Addition 1: Self-Modification Policy Table (MOD-01)

**What:** A new explicit section in AGENTS.md with a table of change types and autonomy levels. Zero ambiguous cases.

**Where:** After the existing "Approval Gate" section — the autonomy table is the positive complement to the approval gate's constraints.

**Pattern:**
```markdown
## Self-Modification Policy

Kiro can modify any of the following without Enrique's approval:

| Change type | Autonomy level | How to apply |
|-------------|----------------|--------------|
| Identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) | Fully autonomous | Edit in `documents/`, commit to git — live immediately |
| config.toml | Fully autonomous | Edit source in module.nix, rebuild — see CLAUDE.md |
| Skills (create, audit, install) | Fully autonomous | `zeroclaw skills audit` then `zeroclaw skills install` |
| module.nix and .nix files | Fully autonomous | Requires nixos-rebuild — read CLAUDE.md first |

**git-first rule:** All document edits must be committed to git at `/etc/nixos/zeroclaw`. The commit IS the deployment for documents/ (symlink is live). For skills, commit after successful install.
```

**Confidence:** HIGH — aligns exactly with CONTEXT.md locked decision and existing CLAUDE.md deployment model table.

### AGENTS.md Addition 2: Strengthened Self-Repair Mandate (RPR-01/02/03)

**What:** Elevate self-repair from a named "protocol" section to Hard Limits language. Expand scope. Add ZeroClaw restart command.

**Pattern for Hard Limits entry:**
```markdown
- Never let a discovered issue go unrecorded: call `memory_store("issue:<timestamp>", ...)` BEFORE attempting any fix, without exception. If filing fails, do not proceed — report immediately.
- Self-repair is mandatory, not optional: if Kiro caused an issue or can fix it, Kiro fixes it. Do not report to Enrique first. File, fix, then report in the next summary.
- ZeroClaw runtime down: attempt `systemctl --user restart zeroclaw` once. If it stays down, report to Enrique immediately.
- Broader system issues: if Kiro caused it (failed nixos-rebuild, broken service), Kiro fixes it. If pre-existing, file a record and report to Enrique.
- Unfixable issues: file durable record → attempt workaround → report to Enrique with what was tried and what is needed.
```

**Pattern for Self-Repair Protocol update:**
- Change opening line from "When an internal tool, skill, or config is broken" to "When Kiro encounters any issue it caused or can fix"
- Step 1 language: make explicit that calling `repair_loop` (when available) is preferred over manual `memory_store`
- Add: repair-loop skill automates Steps 1-2 atomically — invoke it by name when available

**Confidence:** HIGH — derived directly from CONTEXT.md locked decisions.

### repair-loop Skill (SKILL.toml)

**What:** A callable shell tool that atomically fires Step 1 (memory_store) and Step 2 (attempt fix) as a single invocable action.

**Directory:** `/etc/nixos/zeroclaw/skills/repair-loop/`

**Files needed:**
- `SKILL.toml` — registers the tool
- `scripts/repair-loop.sh` — shell implementation

**SKILL.toml pattern:**
```toml
[skill]
name = "repair-loop"
description = "File a durable issue record and attempt repair. Always invoke this before attempting any fix. Usage: repair_loop <issue_description>"
version = "0.1.0"
author = "kiro"
tags = ["resilience", "repair", "memory"]

[[tools]]
name = "repair_loop"
description = "File issue to ZeroClaw memory and attempt repair. Accepts: issue description as argument. Steps: (1) memory_store, (2) attempt fix, (3) update record."
kind = "shell"
command = "/etc/nixos/zeroclaw/skills/repair-loop/scripts/repair-loop.sh"
```

**Shell script pattern (repair-loop.sh):**
```bash
#!/usr/bin/env bash
# repair-loop.sh — file issue record and signal repair attempt
# Usage: repair-loop.sh "<issue_description>"
set -euo pipefail

ISSUE_DESC="${1:-unknown issue}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
KEY="issue:${TIMESTAMP}"

# Step 1: File durable record (non-negotiable)
zeroclaw memory store "${KEY}" "${ISSUE_DESC} | filed: ${TIMESTAMP} | status: repair-attempted"

echo "REPAIR_LOOP_KEY=${KEY}"
echo "REPAIR_LOOP_ISSUE=${ISSUE_DESC}"
echo "REPAIR_LOOP_FILED=true"
# Agent reads this output and proceeds with the actual fix in the current session
```

**Important:** The script files the record and emits structured output for the agent to act on. The actual repair logic happens in the Kiro session after the tool returns — the shell tool cannot execute arbitrary fixes, but it enforces the filing step.

**Confidence:** HIGH for SKILL.toml structure (from skills/README.md). MEDIUM for exact shell implementation — `zeroclaw memory store` command syntax must be confirmed against actual CLI, or use `zeroclaw agent -m "memory_store(...)"`-style invocation.

**Open question:** Exact CLI syntax for `memory_store` from shell. The ZeroClaw memory tool (`memory_store`) is an agent tool, not a shell subcommand. The repair-loop script may need to call `zeroclaw agent -m "Call memory_store(\"${KEY}\", \"${ISSUE_DESC}\")"` instead — or the script prints a structured output that Kiro's session processes as an in-context instruction. The planner should choose: (a) script calls `zeroclaw agent` to invoke memory_store, or (b) script emits a structured marker that the calling Kiro session acts on. Option (b) is simpler and avoids nested agent invocations.

### sentinel Skill (SKILL.md + cron job)

**What:** An instruction-injection skill that teaches Kiro what to do when the sentinel cron fires. The cron job calls `agent -m "Run sentinel"` every 2 hours, which loads the sentinel skill's instructions into context.

**Directory:** `/etc/nixos/zeroclaw/skills/sentinel/`

**Files needed:**
- `SKILL.md` — instructions Kiro follows when sentinel fires

**SKILL.md pattern:**
```markdown
---
name: sentinel
description: Error sentinel — scan ZeroClaw memory for unresolved issues, run repair-loop for each, escalate to Enrique if repair fails. Run by cron every 2 hours.
---

# Sentinel Protocol

You are executing the sentinel check. Follow these steps exactly:

## Steps

1. **Scan for unresolved issues:** Call `memory_recall("issue:")` to list all issue records. Filter to entries that do NOT have a corresponding `issue:<timestamp>:resolved` record. These are unresolved issues.

2. **For each unresolved issue:** Invoke the `repair_loop` tool with the issue description. Wait for the result.

3. **On successful repair:** Call `memory_store("issue:<timestamp>:resolved", "Auto-resolved by sentinel at <timestamp>")`.

4. **On repair failure:** Send an immediate WhatsApp message to Enrique: "Sentinel alert: repair-loop ran for [issue key], failed. [What was tried]. Your input needed." Do NOT defer to EOD summary.

5. **If no unresolved issues:** Exit silently. No message needed.

## Constraints

- Never skip Step 1 — always scan first.
- Never defer escalation to EOD summary when repair fails.
- If memory_recall returns no results for "issue:", log a brief note and exit.
```

**Cron job registration:**
```bash
zeroclaw cron add '0 */2 * * *' 'agent -m "Run the sentinel skill — scan for unresolved issues and trigger repair-loop"'
```

**Confidence:** HIGH for SKILL.md structure. HIGH for cron expression (`0 */2 * * *` = every 2 hours on the hour). MEDIUM for WhatsApp notification mechanism — must use kapso-whatsapp-cli or channel message, not a ZeroClaw native tool (verify against TOOLS.md or channel config).

### IPC Documentation (CLAUDE.md addition)

**What:** A new section in CLAUDE.md explaining how ZeroClaw IPC works and how to configure a second agent instance.

**Source:** `reference/upstream-docs/config-reference.md` — `[agents_ipc]` section (confirmed, read above).

**Confirmed IPC facts (HIGH confidence from official docs):**

| Fact | Source |
|------|--------|
| `[agents_ipc]` section with `enabled`, `db_path`, `staleness_secs` | config-reference.md |
| Default `db_path = "~/.zeroclaw/agents.db"` | config-reference.md |
| Default `staleness_secs = 300` | config-reference.md |
| When enabled: registers tools `agents_list`, `agents_send`, `agents_inbox`, `state_get`, `state_set` | config-reference.md |
| Agent identity derived from `workspace_dir` SHA-256 hash (not user-supplied name) | config-reference.md |
| All agents sharing same `db_path` can discover each other | config-reference.md |
| Default `enabled = false` — no DB created until enabled | config-reference.md |
| Kiro's current config: `enabled = true`, `db_path = "~/.zeroclaw/agents.db"`, `staleness_secs = 300` | Phase 1 config (IPC-01 complete) |

**CLAUDE.md section pattern:**
```markdown
## Multi-Agent IPC

ZeroClaw supports multiple independent agent instances communicating on the same host via a shared SQLite database.

### How IPC Works

IPC is enabled by the `[agents_ipc]` config section. When enabled, ZeroClaw registers five tools in the agent's session:

| Tool | Purpose |
|------|---------|
| `agents_list` | Discover agents registered in the shared DB |
| `agents_send` | Send a message to another agent |
| `agents_inbox` | Read messages addressed to this agent |
| `state_get` | Read shared state by key |
| `state_set` | Write shared state by key |

All agents that share the same `db_path` can see each other. Agent identity is derived from `workspace_dir` (SHA-256 hash) — not a user-supplied name.

### Configuring a Second Agent Instance

A second ZeroClaw instance must point to the same `db_path` as Kiro to participate in IPC:

```toml
[agents_ipc]
enabled = true
db_path = "~/.zeroclaw/agents.db"   # Same path as Kiro — shared state
staleness_secs = 300                 # Agents not seen in 5 minutes are considered offline
```

The second instance needs its own workspace directory (different `ZEROCLAW_WORKSPACE` or separate `~/.zeroclaw/` setup). It does NOT need the same config.toml — only the same `db_path`.

### Staleness

An agent is considered offline if it has not registered a heartbeat within `staleness_secs`. Default is 300 seconds (5 minutes). Use `agents_list` to check which agents are currently online.
```

**Confidence:** HIGH — derived entirely from config-reference.md official docs.

### MOD-04 Test Documentation Pattern

**What:** The plan documents the exact command; Enrique runs it manually.

**Plan task content:**
```
## MOD-04: Live Self-Modification Test

This task documents the validation command for MOD-04.

**To execute (Enrique runs this after reviewing the plan):**
zeroclaw agent -m "Create documents/TEST.md with a timestamped test entry, commit it to git in /etc/nixos/zeroclaw, and confirm the commit with git log. Then delete documents/TEST.md and commit the deletion."

**Verification:** `git log` shows two commits (create + delete TEST.md) from the Kiro session.

**No cleanup needed** — the command instructs Kiro to delete TEST.md in the same session.
```

**Confidence:** HIGH — aligns with CONTEXT.md locked decision and CLAUDE.md deployment model (documents/ are live via symlink, git is accessible).

### Anti-Patterns to Avoid

- **SKILL.md for repair-loop:** Using SKILL.md (instructions only) instead of SKILL.toml means repair behavior is not invocable as a named tool — Kiro can ignore it. SKILL.toml registers a callable tool.
- **Creating a shell script at a path not tracked in git:** Skill scripts must live inside the skill directory in `/etc/nixos/zeroclaw/skills/` — they are the git source of truth.
- **Symlinks inside skill packages:** `zeroclaw skills audit` will reject any skill containing symlinks. All files must be regular files.
- **Relative paths in SKILL.toml `command`:** Must use absolute paths — `skills/README.md` explicitly states this.
- **Creating YAML cron files:** ZeroClaw has no file-based cron. Sentinel cron must be added via `zeroclaw cron add`.
- **Editing `~/.zeroclaw/` directly:** Always edit source in `/etc/nixos/zeroclaw/`, then deploy via CLI. Runtime-managed paths are overwritten.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Durable issue tracking | Custom log files or chat context | `memory_store("issue:<timestamp>", ...)` | ZeroClaw memory survives context resets; files don't have structured recall |
| Recurring sentinel scan | systemd timers, Python scripts | `zeroclaw cron add '0 */2 * * *' 'agent -m ...'` | Only cron method in ZeroClaw; systemd timers can't run agent sessions |
| Callable repair behavior | Prose in AGENTS.md | SKILL.toml with `[[tools]]` block | Tools are invocable by name in agent sessions; prose can be skipped |
| WhatsApp notification | Direct WhatsApp API | kapso-whatsapp-cli (already configured via channel) | Established delivery mechanism on this machine |
| IPC messaging | Custom SQLite writes | `agents_send` / `agents_inbox` ZeroClaw tools | ZeroClaw manages the agents.db schema — direct writes would be overwritten |

**Key insight:** Every "build a custom solution" impulse in this phase maps to an existing ZeroClaw mechanism. The OpenClaw lesson reinforces this — Kiro found issues and reported them without fixing them because documentation alone doesn't enforce behavior. Tools and cron enforce behavior regardless of in-session compliance.

---

## Common Pitfalls

### Pitfall 1: repair-loop shell script uses agent tool as shell subcommand

**What goes wrong:** Script calls `zeroclaw memory store "key" "value"` — this command does not exist. `memory_store` is an agent tool, not a CLI subcommand.

**Why it happens:** Conflating agent tools (available inside a session) with CLI subcommands (available in shell).

**How to avoid:** Either (a) script calls `zeroclaw agent -m "Call memory_store(...)"` (nested agent invocation — expensive), or (b) script emits structured output markers that the calling Kiro session reads and acts on with its own `memory_store` tool. Option (b) is preferred — lighter, no recursive agent calls.

**Warning signs:** `zeroclaw memory` returning "unknown subcommand" in shell.

### Pitfall 2: Sentinel SKILL.md instructions too vague for `memory_recall` filtering

**What goes wrong:** `memory_recall("issue:")` returns all keys prefixed with "issue:", including resolved ones (`issue:<timestamp>:resolved`). If the sentinel doesn't filter correctly, it retriggers repair-loop on already-resolved issues.

**Why it happens:** `memory_recall` prefix matching returns all matching keys — the sentinel must compare pairs.

**How to avoid:** Sentinel instructions must explicitly state: collect all keys matching `issue:`, then subtract any that have a corresponding `issue:<timestamp>:resolved` entry. The unresolved set is what remains.

**Warning signs:** Sentinel sending escalation messages for issues that were already resolved.

### Pitfall 3: Symlink inside repair-loop skill package

**What goes wrong:** `zeroclaw skills audit` rejects the skill with a symlink error before install.

**Why it happens:** The `scripts/` subdirectory inside a skill must contain regular files. If `repair-loop.sh` is a symlink to anywhere else, audit fails.

**How to avoid:** Create the script file directly in `/etc/nixos/zeroclaw/skills/repair-loop/scripts/repair-loop.sh` as a regular file. Never symlink from inside a skill package.

**Warning signs:** `zeroclaw skills audit` output containing "symlink rejected" or similar.

### Pitfall 4: AGENTS.md self-repair language still sounds optional after edit

**What goes wrong:** Adding self-repair to Hard Limits but using soft language ("should file", "try to repair") instead of absolute language ("must file", "non-negotiable").

**Why it happens:** Copy-paste from existing protocol section which uses softer framing.

**How to avoid:** Hard Limits section already uses absolute phrasing ("Never", "No exceptions"). The self-repair addition must match this pattern — "Never attempt a repair without first filing a durable record."

**Warning signs:** New self-repair Hard Limits entries containing "should", "try", "when possible".

### Pitfall 5: MOD-04 test instruction leaves TEST.md committed

**What goes wrong:** Kiro creates `documents/TEST.md` and commits it, but doesn't delete it in the same session — leaving a permanent artifact in the documents/ directory.

**Why it happens:** The agent prompt doesn't explicitly require deletion.

**How to avoid:** The plan's MOD-04 command must include deletion: "...then delete documents/TEST.md and commit the deletion." CONTEXT.md already specifies this — the plan must relay it verbatim to Enrique.

**Warning signs:** `git log` showing only one commit (create) but not the second (delete).

---

## Code Examples

### SKILL.toml — repair-loop (complete)

```toml
# Source: skills/README.md SKILL.toml spec
[skill]
name = "repair-loop"
description = "File a durable issue record and attempt repair. Always invoke repair_loop before attempting any fix. Usage: repair_loop <issue_description>"
version = "0.1.0"
author = "kiro"
tags = ["resilience", "repair", "memory"]

[[tools]]
name = "repair_loop"
description = "File issue to ZeroClaw memory and begin repair. Accepts issue description as argument. Returns structured output with the memory key for follow-up updates."
kind = "shell"
command = "/etc/nixos/zeroclaw/skills/repair-loop/scripts/repair-loop.sh"
```

### SKILL.md — sentinel (frontmatter)

```markdown
# Source: skills/README.md SKILL.md spec
---
name: sentinel
description: Error sentinel — scans ZeroClaw memory every 2 hours for unresolved issues, triggers repair-loop, escalates to Enrique via WhatsApp if repair fails.
---
```

### Cron registration — sentinel

```bash
# Source: cron/README.md — standard cron add pattern
# '0 */2 * * *' = every 2 hours on the hour (00:00, 02:00, 04:00, ...)
zeroclaw cron add '0 */2 * * *' 'agent -m "Run the sentinel skill — scan for unresolved issues and trigger repair-loop for each"'

# Verify
zeroclaw cron list
```

### AGENTS.md Hard Limits additions — self-repair

```markdown
# Source: existing AGENTS.md Hard Limits pattern
- Never attempt a repair without first filing a durable record: call `memory_store("issue:<timestamp>", ...)` BEFORE attempting any fix. No exceptions. If repair_loop skill is available, invoke it instead of calling memory_store directly.
- Self-repair scope is unconditional: if Kiro caused an issue or can fix it, Kiro fixes it before reporting to Enrique. Filing + fixing + reporting in next summary is the correct sequence.
- ZeroClaw runtime down: `systemctl --user restart zeroclaw` once. If still down after restart, report to Enrique immediately.
```

### memory_store pattern — existing (from AGENTS.md)

```
# Source: AGENTS.md Durable Tracking section — existing established pattern
memory_store("issue:<timestamp>", "title | type | priority | description")
memory_store("issue:<timestamp>:resolved", "Fixed by <what>")
memory_recall("issue:<timestamp>")
```

### agents_ipc config — confirmed from upstream docs

```toml
# Source: reference/upstream-docs/config-reference.md [agents_ipc] section
[agents_ipc]
enabled = true
db_path = "~/.zeroclaw/agents.db"
staleness_secs = 300
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| AGENTS.md self-repair as a named "protocol" section | Self-repair in Hard Limits + callable SKILL.toml tool | Phase 3 change — harder to skip |
| Sentinel as future v2 scope | Sentinel in Phase 3 (expanded from discussion) | CONTEXT.md explicitly added sentinel to Phase 3 scope |
| repair_loop as prose instructions only | repair_loop as a callable agent tool (SKILL.toml) | Tool invocation is more enforceable than prose instructions |
| OpenClaw cron via YAML files | ZeroClaw cron via CLI only | Architecture difference — wrong method doesn't exist |
| OpenClaw task queue | ZeroClaw memory (`memory_store`/`memory_recall`) | Phase 2 decision — task-queue skill is v2/CRN-01 |

**Deprecated/outdated:**
- OpenClaw cron-sync: does not exist in ZeroClaw
- File-based cron definitions: not supported
- Task Queue Protocol: replaced by Durable Tracking in Phase 2

---

## Open Questions

1. **repair_loop shell script: how to invoke memory_store from shell**
   - What we know: `memory_store` is an agent tool (available in session), not a `zeroclaw` CLI subcommand
   - What's unclear: whether `zeroclaw` CLI has any `memory` subcommand; whether calling `zeroclaw agent -m "..."` from a shell tool creates a nested agent session
   - Recommendation: Default to option (b) — script emits structured markers, Kiro's session reads them and calls `memory_store` directly. Script becomes a signaling mechanism, not a ZeroClaw API caller. Planner should encode this as the design decision.

2. **WhatsApp notification mechanism for sentinel escalation**
   - What we know: kapso-whatsapp-cli is on PATH (from TOOLS.md/LORE.md context), used for Enrique notifications
   - What's unclear: exact kapso-whatsapp-cli command signature for sending a message in sentinel skill context
   - Recommendation: Sentinel SKILL.md instructions should use ZeroClaw's channel tools if available, or reference kapso-whatsapp-cli. Planner should check TOOLS.md for confirmed command syntax before writing sentinel instructions.

3. **Sentinel memory query: exact memory_recall behavior for prefix matching**
   - What we know: `memory_recall("issue:")` prefix pattern established in AGENTS.md
   - What's unclear: whether `memory_recall` returns all keys with that prefix or requires an exact key match
   - Recommendation: Assume prefix matching (consistent with how the pattern is documented in AGENTS.md). If it's exact-match only, sentinel will need a different strategy. Planner should note this as a runtime-validation step in the sentinel plan.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual + CLI verification (no automated test suite) |
| Config file | None — all validation via CLI commands and `git log` |
| Quick run command | `zeroclaw skills list && zeroclaw cron list` |
| Full suite command | See Phase Requirements → Test Map below |

This phase is behavioral documentation + skill authoring. There is no code to unit test. Validation is: correct files exist, skills install cleanly, cron job appears in list, and MOD-04 live test succeeds.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MOD-01 | AGENTS.md contains explicit self-modification autonomy table with no ambiguous cases | Manual audit | `grep -n "Self-Modification" /etc/nixos/zeroclaw/documents/AGENTS.md` | ❌ Wave 0: AGENTS.md edit |
| MOD-04 | Kiro creates, commits, and deletes TEST.md in live session | Manual (Enrique runs) | `git log --oneline -- documents/TEST.md` after test | ❌ Wave 0: MOD-04 task |
| RPR-01 | AGENTS.md self-repair covers "any issue Kiro caused or can fix" | Manual audit | `grep -n "caused or can fix" /etc/nixos/zeroclaw/documents/AGENTS.md` | ❌ Wave 0: AGENTS.md edit |
| RPR-02 | Self-repair in Hard Limits with `systemctl --user restart zeroclaw` | Manual audit | `grep -n "systemctl" /etc/nixos/zeroclaw/documents/AGENTS.md` | ❌ Wave 0: AGENTS.md edit |
| RPR-03 | repair-loop skill installs cleanly and registers tool | CLI smoke | `zeroclaw skills list \| grep repair-loop` | ❌ Wave 0: skill creation |
| IPC-03 | CLAUDE.md contains agents_ipc section with db_path and tool list | Manual audit | `grep -n "agents_ipc" /etc/nixos/zeroclaw/CLAUDE.md` | ❌ Wave 0: CLAUDE.md edit |

### Sampling Rate

- **Per task commit:** `zeroclaw skills list` (after skill install tasks), `git log --oneline -5` (after document edits)
- **Per wave merge:** `zeroclaw skills list && zeroclaw cron list && zeroclaw doctor`
- **Phase gate:** All grep checks pass + `zeroclaw skills list` shows `repair-loop` and `sentinel` + `zeroclaw cron list` shows sentinel entry + MOD-04 manual test passes before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] No automated test files needed — all validation is CLI-based for this behavioral documentation phase
- [ ] MOD-04 requires a live Kiro session (manual step) — cannot be automated in advance
- [ ] Sentinel memory query behavior (prefix vs exact match) must be validated at runtime when sentinel first fires

*(No test framework installation needed — CLI tools and grep are sufficient for this phase)*

---

## Sources

### Primary (HIGH confidence)

- `/etc/nixos/zeroclaw/reference/upstream-docs/config-reference.md` — `[agents_ipc]` section: enabled, db_path, staleness_secs, IPC tool names (agents_list, agents_send, agents_inbox, state_get, state_set), agent identity derivation
- `/etc/nixos/zeroclaw/skills/README.md` — SKILL.toml format, `[[tools]]` block fields, directory structure rules (no symlinks), absolute path requirement for `command`
- `/etc/nixos/zeroclaw/cron/README.md` — cron expression syntax, `zeroclaw cron add` command signature, `'0 */2 * * *'` pattern verification
- `/etc/nixos/zeroclaw/documents/AGENTS.md` — existing Self-Repair Protocol, Hard Limits pattern, memory_store/memory_recall usage, existing "never ask, just do" autonomy list

### Secondary (MEDIUM confidence)

- `/etc/nixos/zeroclaw/03-CONTEXT.md` — locked decisions, implementation specifics, deferred scope — treated as authoritative user decisions
- `.planning/REQUIREMENTS.md` — requirement IDs and descriptions

### Tertiary (LOW confidence)

- Exact `memory_recall` prefix-matching behavior — assumed from AGENTS.md documentation pattern but not verified against CLI help or upstream docs
- `zeroclaw` CLI memory subcommand availability — not verified; assumed agent-tool-only based on config-reference.md which documents no memory CLI subcommand

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools and formats confirmed from local official docs
- Architecture patterns: HIGH for structure, MEDIUM for repair-loop shell implementation detail
- Pitfalls: HIGH — derived from confirmed deployment model and skills/cron constraints
- IPC documentation content: HIGH — sourced entirely from config-reference.md
- repair-loop shell implementation: MEDIUM — `memory_store` shell invocation method is an open question

**Research date:** 2026-03-04
**Valid until:** 2026-04-04 (ZeroClaw config-reference.md dated 2026-02-25; stable for ~30 days)
