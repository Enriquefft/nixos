# Phase 3: Self-Modification and Resilience - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish Kiro's behavioral constitution and enforcement infrastructure:
- AGENTS.md: explicit git-first self-modification policy (MOD-01) and strengthened self-repair mandate (RPR-01/02/03)
- CLAUDE.md: multi-agent IPC documentation (IPC-03)
- New skill: `repair-loop` — makes the file → attempt → report protocol an invocable tool
- New cron + skill: error sentinel — scans ZeroClaw memory every 2 hours for unresolved issues, triggers repair-loop, escalates to Enrique if repair fails
- MOD-04 validation: live end-to-end test (manual step — you run it after reviewing)

Self-modification means Kiro editing its own config and documents. Resilience means unresolved issues don't silently persist.

</domain>

<decisions>
## Implementation Decisions

### Self-modification autonomy boundaries (MOD-01)
All four change types are fully autonomous — no approval required for any:

| Change type | Autonomy level |
|-------------|----------------|
| Identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) | Fully autonomous |
| config.toml (autonomy level, allowed_commands, agent limits, memory settings) | Fully autonomous |
| Skills (create, audit, install via zeroclaw CLI) | Fully autonomous |
| module.nix and other .nix files (requires nixos-rebuild) | Fully autonomous |

This must be documented in AGENTS.md as an explicit policy section with no ambiguous cases (MOD-01).

### Self-repair mandate scope (RPR-01/02/03)
- Strengthen existing Self-Repair Protocol in AGENTS.md — expand scope language from "internal tool, skill, or config" to "any issue Kiro caused or can fix"
- ZeroClaw runtime crashes: Kiro attempts `systemctl --user restart zeroclaw` once, then reports to Enrique if it stays down
- Broader system issues (failed nixos-rebuild, broken system service): if Kiro caused it, Kiro fixes it; if pre-existing, report and wait
- Move self-repair from "protocol" section to Hard Limits framing — filing before attempting is non-negotiable, not a suggestion
- Unfixable issues: file durable record → attempt workaround → report to Enrique with what was tried and what's needed
- RPR-03 (durable records before repair): already implemented via memory_store Step 1 — strengthen, don't replace

### repair-loop skill
- Create `repair-loop` skill as SKILL.toml with a callable shell tool
- Tool signature: `repair-loop <issue_description>` — atomically calls `memory_store` to file the record (Step 1 is enforced by the tool, not just docs)
- Makes the behavior invocable by name — harder to skip than prose in AGENTS.md
- Phase 3 creates this skill and installs it

### Error sentinel (new scope — expanded from discussion)
- A cron-based enforcement mechanism that doesn't rely on Kiro's in-session compliance
- **Scan strategy:** Query ZeroClaw memory for issue records without a `:resolved` counterpart (`memory_recall("issue:")`, filter unresolved)
- **Frequency:** Every 2 hours
- **On unresolved issue found:** Run repair-loop for each outstanding issue
- **On repair failure:** Notify Enrique immediately via WhatsApp (not EOD summary) — "repair-loop ran for [issue], failed: [what was tried]. Your input needed."
- Phase 3 creates: a `sentinel` skill + adds the sentinel cron job via `zeroclaw cron add`

### MOD-04 end-to-end test
- Real execution (not docs-only validation)
- Test document: `documents/TEST.md` — created specifically for the test, not a real identity doc
- Manual step: plan documents the test command, Enrique runs it after reviewing the plan
  - Command: `zeroclaw agent -m "Create documents/TEST.md with a timestamped test entry, commit it to git in /etc/nixos/zeroclaw, and confirm the commit with git log"`
- Cleanup: same plan task deletes TEST.md and commits the deletion — leaves no trace
- Verification: `git log` shows two commits (create + delete TEST.md) from the Kiro session

### IPC documentation (CLAUDE.md)
- Scope: config reference + concept explanation — not a full operational guide
- Content: explain how agents_ipc works (shared db_path at `~/.zeroclaw/agents.db`, staleness_secs, how agents register/discover each other)
- Second instance uses the SAME db_path as Kiro — shared state, agents see each other
- Focus on the mechanism (how IPC works) not a specific use case (use case is TBD)
- Enough for an agent to configure a second instance without further guidance

### Claude's Discretion
- Exact shell script implementation for repair-loop tool command
- Exact sentinel skill implementation (how memory query is structured)
- SKILL.toml field structure for both skills
- Section ordering and heading style in AGENTS.md additions
- IPC section placement and heading in CLAUDE.md

</decisions>

<specifics>
## Specific Ideas

- OpenClaw lesson: Kiro found issues, reported them, but didn't fix them even when instructed. Root cause: documentation alone doesn't enforce behavior. The repair-loop skill + sentinel cron architecture addresses this directly.
- OpenClaw lesson: Kiro used wrong cron method (file-based instead of version-controlled). ZeroClaw architecturally solves this — `zeroclaw cron` is the only method; the wrong method doesn't exist.
- Sentinel is reactive enforcement (post-hoc), not preventive (hooks). ZeroClaw has no native pre/post-tool hook system. A future phase could implement an error-sentinel-v2 using `zeroclaw doctor traces` to catch untracked errors (not just explicitly filed issues).
- MOD-04 test is manual: the plan provides the exact command to run, but Enrique executes it to trigger the live Kiro session.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AGENTS.md` Self-Repair Protocol (lines ~104+): Step 1 is `memory_store` — confirm this is the filing hook the repair-loop skill replaces/augments
- `AGENTS.md` Hard Limits section: existing pattern for non-negotiable rules — self-repair mandate goes here
- `skills/README.md`: complete guide for SKILL.md and SKILL.toml formats — repair-loop and sentinel skills follow this
- `cron/README.md`: complete guide for `zeroclaw cron add` — sentinel cron uses this
- `reference/upstream-docs/config-reference.md`: IPC config knobs (`[agents_ipc]` section) — researcher reads this for IPC doc content

### Established Patterns
- `memory_store("issue:<timestamp>", ...)` / `memory_store("issue:<timestamp>:resolved", ...)` — existing durable tracking pattern; sentinel scans for unresolved issue keys
- Hard Limits in AGENTS.md: absolute, no-exception rules — self-repair and self-modification policies follow this framing
- `zeroclaw skills audit ./skills/<name>` then `zeroclaw skills install` — established skill deploy pattern for both new skills

### Integration Points
- AGENTS.md: two new sections (self-modification policy table, strengthened self-repair mandate)
- CLAUDE.md: one new section (IPC documentation, after existing deployment model section)
- `skills/repair-loop/`: new skill directory with SKILL.toml
- `skills/sentinel/`: new skill directory with SKILL.md + supporting script
- Sentinel cron: added via `zeroclaw cron add '0 */2 * * *' ...` (every 2 hours)

</code_context>

<deferred>
## Deferred Ideas

- **Error-sentinel-v2 using zeroclaw doctor traces**: Phase 3 sentinel scans memory for explicitly filed issues. A future sentinel-v2 could additionally scan `zeroclaw doctor traces --event tool_call_result --contains "error"` to catch untracked errors Kiro didn't file. This closes the gap where Kiro encounters an error but doesn't invoke repair-loop at all.
- **ZeroClaw hooks feature request**: Pre/post-tool hooks (like Claude Code) would enable true preventive enforcement — block or validate before tool execution. Would eliminate reliance on Kiro's in-session compliance. Worth filing upstream with ZeroClaw.

</deferred>

---

*Phase: 03-self-modification-and-resilience*
*Context gathered: 2026-03-04*
