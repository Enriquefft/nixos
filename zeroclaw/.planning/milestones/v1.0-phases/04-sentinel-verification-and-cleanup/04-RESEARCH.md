# Phase 4: Sentinel Verification and Cleanup - Research

**Researched:** 2026-03-04
**Domain:** ZeroClaw memory API, sentinel skill, cron live testing, GSD verification/validation workflow, skills/README.md documentation
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RPR-03 | All discovered issues are filed as durable records (not just chat context) before attempting repair — automated sentinel detection unverified | Phase 3 installed sentinel skill and cron job. Phase 4 closes the gap: the `memory_recall("issue:")` prefix behavior is unverified in live conditions. Live end-to-end sentinel test (seed issue → confirm sentinel detects → repair attempted) closes RPR-03 fully. |
</phase_requirements>

---

## Summary

Phase 4 is a verification and cleanup phase — not a feature-building phase. All code, skills, and cron infrastructure are already deployed from Phase 3. This phase has five discrete deliverables that fall into three categories: (1) sentinel API verification and potential sentinel SKILL.md fix, (2) sentinel live end-to-end test, and (3) Phase 3 documentation debt (VERIFICATION.md, VALIDATION.md sign-off, skills/README.md correction).

The central open question from Phase 3 research is whether `memory_recall("issue:")` performs prefix matching (returns all keys with that prefix) or requires an exact key match. The ZeroClaw CLI confirms that `zeroclaw memory list` does not support prefix filtering — it only supports `--category` and `--session` filters. This means `memory_recall("issue:")` as an agent tool must be verified at runtime: either it performs prefix scan (the intended behavior) or the sentinel SKILL.md must be rewritten to use a confirmed pattern (e.g., using `memory list --category core` and client-side filtering, or a different scan approach).

No NixOS rebuild is required for any Phase 4 deliverable. Sentinel SKILL.md changes deploy via `zeroclaw skills audit` + `zeroclaw skills install`. Phase 3 VERIFICATION.md is a new document. VALIDATION.md already exists with `nyquist_compliant: false` and needs a sign-off update. skills/README.md is a live-edit document tracked in git.

**Primary recommendation:** Execute as one plan in three waves: (1) verify memory_recall API and fix sentinel if needed, (2) run live sentinel end-to-end test by seeding an issue and triggering sentinel manually, (3) generate Phase 3 VERIFICATION.md, sign off VALIDATION.md, and patch skills/README.md.

---

## Standard Stack

### Core

| Component | Location | Purpose | Why Standard |
|-----------|----------|---------|--------------|
| `memory_recall` | ZeroClaw agent tool (in-session only) | Query stored memory entries | Established pattern from Phase 2/3; sentinel uses it for issue scanning |
| `memory_store` | ZeroClaw agent tool (in-session only) | Store key-value memory entries | Used by repair-loop for durable issue filing |
| `zeroclaw memory get <key>` | CLI subcommand | Inspect a specific memory entry by exact key | Available CLI — useful for seeding verification test entries |
| `zeroclaw cron list` | CLI subcommand | Verify sentinel cron job is registered | Confirms `1f80a4ae-da3c-4498-a6d6-637fc7aed082` still present |
| `zeroclaw agent -m "..."` | CLI — starts agent session | Manually trigger sentinel for live test | Standard way to invoke a cron-equivalent session |
| `zeroclaw skills audit` + `zeroclaw skills install` | CLI | Deploy updated sentinel SKILL.md if needed | Established skill update workflow |
| `git commit` | Shell | Commit VERIFICATION.md, VALIDATION.md, skills/README.md changes | Standard commit pattern in this repo |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| `zeroclaw memory list` | List all memory entries (no prefix filter) | Verify seeded issue entry is present before running sentinel |
| `zeroclaw memory stats` | Check memory backend health | Sanity check before live test — backend: sqlite, healthy |
| `zeroclaw skills list` | Confirm sentinel skill is installed | Pre-flight before live test |
| GSD VERIFICATION.md template | Standard format for phase verification | Generating Phase 3 VERIFICATION.md |

### CLI Memory Subcommand Reality (CRITICAL)

The `zeroclaw memory` CLI provides:
- `memory list [--category <cat>] [--session <s>] [--limit N] [--offset N]` — list entries
- `memory get <key>` — exact key lookup only
- `memory stats` — backend health
- `memory clear` — batch clear by category/key

There is **no prefix filter** in the CLI. The CLI cannot replicate what `memory_recall("issue:")` does as an agent tool. The agent tool and CLI are separate interfaces to the same SQLite backend.

**What this means for Phase 4:** The only way to verify `memory_recall("issue:")` prefix behavior is to run a live agent session, seed an `issue:` key via `memory_store`, then call `memory_recall("issue:")` and observe whether prefix matching occurs. The CLI cannot confirm or deny this.

---

## Architecture Patterns

### Pattern 1: Seeded Live Sentinel Test

**What:** Create a known issue record in memory, then trigger a sentinel session manually to confirm the sentinel detects and processes it.

**When to use:** Exactly once in Phase 4 — this is the end-to-end validation for RPR-03.

**Steps:**
1. Run `zeroclaw agent -m "Call memory_store to file a test issue: memory_store('issue:2026-03-04T00:00:00Z', 'TEST: Seeded sentinel verification issue | type: test | priority: low | description: Intentional test entry for sentinel verification')"` — seeds the issue
2. Confirm with `zeroclaw memory list` that the entry appears (it will show as `[conversation]` or another category depending on how memory_store saves custom keys)
3. Run `zeroclaw agent -m "Run the sentinel skill — scan ZeroClaw memory for unresolved issues and trigger repair-loop for each. Escalate to Enrique via WhatsApp if any repair fails."` — manually invokes sentinel
4. Observe whether sentinel detects the seeded entry
5. After test, clean up: `zeroclaw agent -m "Call memory_store to mark the test issue resolved: memory_store('issue:2026-03-04T00:00:00Z:resolved', 'Test issue cleaned up — sentinel verification complete')"`

**Key variable:** Whether step 4 detects the seeded entry depends on `memory_recall("issue:")` behavior. If it works, the test passes. If not, sentinel SKILL.md must be updated before retesting.

### Pattern 2: Sentinel SKILL.md Update (if memory_recall prefix scan fails)

**What:** If live test shows `memory_recall("issue:")` does not perform prefix scan, update the sentinel skill to use a confirmed scan approach.

**Alternative approaches to research if needed:**
- `memory_recall` with no arguments or wildcard — returns all entries, sentinel filters client-side
- `zeroclaw memory list` piped output — shell-based, not available in agent session
- Use a sentinel-specific memory category — store issues as `category: "sentinel"` and recall by category

**Deployment after fix:**
```bash
cd /etc/nixos/zeroclaw
zeroclaw skills audit ./skills/sentinel
zeroclaw skills install ./skills/sentinel
zeroclaw skills list | grep sentinel
git add skills/sentinel/SKILL.md
git commit -m "fix(skills): update sentinel memory scan to use confirmed API pattern"
```

### Pattern 3: Phase 3 VERIFICATION.md Generation

**What:** Generate `.planning/phases/03-self-modification-and-resilience/03-VERIFICATION.md` following the GSD verification report template format.

**Source material for populating the report:**
- Phase 3 plan files (03-01 through 03-04) contain `must_haves.truths` and `must_haves.artifacts` — these are the verification checklist
- `03-UAT.md` has already captured all 6 tests as PASSED — this is the evidence base
- Phase 3 ROADMAP.md success criteria are the top-level truths to verify

**Phase 3 truths to verify (from ROADMAP.md and plan must_haves):**
1. Kiro edits a test identity document, commits it, `git log` shows the commit — verified via MOD-04 (git log confirms commits 45d21fc, b3960f8, 19b3f7b)
2. AGENTS.md distinguishes what Kiro can change autonomously vs what requires approval — verified via grep for "Self-Modification Policy" section
3. Kiro files a durable record before attempting repair — verified via repair_loop skill (zeroclaw skills list shows repair-loop v0.1.0)
4. An additional ZeroClaw agent instance can be configured via IPC documentation in CLAUDE.md — verified via grep for "agents_ipc" in CLAUDE.md

**VERIFICATION.md frontmatter:**
```markdown
---
phase: 03-self-modification-and-resilience
verified: 2026-03-05T00:20:00Z
status: passed
score: 6/6 must-haves verified
---
```

Evidence is pre-collected in 03-UAT.md — VERIFICATION.md is a formal re-expression of what was already confirmed.

### Pattern 4: VALIDATION.md Sign-Off

**What:** Update `.planning/phases/03-self-modification-and-resilience/03-VALIDATION.md` from `nyquist_compliant: false` to `nyquist_compliant: true` and sign off all checklist items.

**Current state of 03-VALIDATION.md:**
```yaml
status: draft
nyquist_compliant: false
wave_0_complete: false
```

**All 7 tasks in the Per-Task Verification Map are pending (status: ⬜) — these need to be updated to ✅ green based on UAT results.**

**What needs to change:**
1. Frontmatter: `status: complete`, `nyquist_compliant: true`, `wave_0_complete: true`
2. Per-Task Verification Map: all 7 rows updated to `✅ green`
3. Wave 0 Requirements checklist: all 3 items checked
4. Validation Sign-Off checklist: all 6 items checked
5. Approval line: `pending` → `approved`

### Pattern 5: skills/README.md Documentation Fix

**What:** The skills/README.md has a documentation gap — it does not mention that `.sh` files (shell scripts) cannot be placed inside skill packages. The no-symlinks rule is clearly documented, but the `.sh` file restriction is not.

**Evidence for the gap:** Phase 3, Plan 02 decision log notes: "Script moved to bin/repair-loop.sh (outside skill package) — zeroclaw audit rejects .sh files inside skill packages by security policy." The current skills/README.md says "All files inside a skill directory must be regular files — no symlinks allowed" but does not mention the `.sh` restriction.

**Required addition:** A note in the "Important" block under Directory Structure (line 40) and/or in the audit check description that `.sh` files inside skill packages are rejected by the ZeroClaw security audit, not just symlinks.

**Current text (line 40):**
```
**Important:** All files inside a skill directory must be **regular files** — no symlinks allowed inside skill packages. The `zeroclaw skills audit` command will reject any skill that contains symlinks, even in subdirectories. Copy files; never symlink them.
```

**Required addition:**
A sentence clarifying that shell scripts (`.sh` files) also cannot be placed inside skill packages — scripts that tools invoke must live outside the skill directory (e.g., in `/etc/nixos/zeroclaw/bin/`) and be referenced via absolute path in the `command` field.

### Anti-Patterns to Avoid

- **Assuming memory_recall supports prefix scan without live verification:** The CLI `memory get` is exact-key only. The agent tool behavior is separate and unverified. Never update VALIDATION.md claiming RPR-03 is fully closed before the live sentinel test.
- **Triggering the sentinel cron and waiting 2 hours:** Do not wait for the scheduled cron. Use `zeroclaw agent -m "Run the sentinel skill..."` to trigger it manually for the live test.
- **Editing 03-VALIDATION.md before generating 03-VERIFICATION.md:** Generate VERIFICATION.md first (it is the evidence base), then sign off VALIDATION.md referencing it.
- **Patching skills/README.md without committing:** This file is live-edit (git-tracked). The commit IS the documentation update — changes are immediately visible.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Prefix key scanning in CLI | Custom SQLite queries against `~/.zeroclaw/workspace/cron/jobs.db` | `zeroclaw agent -m "memory_recall('issue:')"` | ZeroClaw manages the SQLite schema — direct writes/reads are overwritten |
| Live sentinel trigger | Writing a shell script to simulate cron | `zeroclaw agent -m "Run the sentinel skill..."` | Standard agent invocation pattern — same context as cron |
| VERIFICATION.md from scratch | Custom format | GSD verification-report.md template | Template is the expected format the planner + verifier consumes |
| Issue seed for live test | Complex setup | Single `memory_store` call in an agent session | Memory store is the established pattern — one tool call is sufficient |

---

## Common Pitfalls

### Pitfall 1: memory_recall prefix scan is actually exact-match

**What goes wrong:** Sentinel calls `memory_recall("issue:")` and gets an empty result — or gets only the literal key "issue:" if it exists — rather than all keys prefixed with "issue:".

**Why it happens:** The agent tool API is separate from the CLI. Phase 3 research flagged this as LOW confidence (unverified). If `memory_recall` requires an exact key, the sentinel will always find nothing and never fire.

**How to avoid:** The live test in Phase 4 reveals this. If the test fails (sentinel finds nothing after seeding), update sentinel SKILL.md to use an alternative scan strategy confirmed in that session.

**Warning signs:** Sentinel agent session exits silently even after a test issue has been stored in memory.

### Pitfall 2: Seeded test issue persists and real sentinel fires on it

**What goes wrong:** After the live test, the seeded `issue:2026-03-04T00:00:00Z` entry remains in memory without a `:resolved` pair. The next scheduled sentinel run at 02:00 detects it and triggers a real repair attempt and potentially a WhatsApp message to Enrique.

**Why it happens:** The cleanup step is easy to forget — it is the last step of the live test.

**How to avoid:** The live test plan must include an explicit cleanup step: after sentinel test passes, file the `:resolved` record. Alternatively, use `zeroclaw memory clear --key "issue:2026-03-04T00:00:00Z"` if that CLI option exists (needs verification), or seed with a timestamp far in the future that is clearly a test.

**Warning signs:** Enrique receives an unexpected WhatsApp alert after the test.

### Pitfall 3: VALIDATION.md sign-off done before VERIFICATION.md exists

**What goes wrong:** VALIDATION.md is updated to `nyquist_compliant: true` but there is no VERIFICATION.md to reference. The approval is unsubstantiated.

**Why it happens:** VALIDATION.md update feels like the simpler task and is attempted first.

**How to avoid:** Generate and commit VERIFICATION.md first. Then update VALIDATION.md with reference to the VERIFICATION.md evidence. This is the correct sequence in the GSD workflow.

### Pitfall 4: skills/README.md fix is incomplete — only mentions "regular files" rule

**What goes wrong:** The README is updated to clarify `.sh` files cannot be inside skill packages, but does not clearly say WHERE scripts should live instead (the bin/ directory outside the skill package).

**Why it happens:** Saying what's forbidden without saying what to do instead leaves the reader stuck.

**How to avoid:** The patch must include both the restriction and the approved alternative: "Shell scripts invoked by skill tools must live outside the skill package, e.g., at `/etc/nixos/zeroclaw/bin/<script>.sh`. Reference them via absolute path in the SKILL.toml `command` field."

---

## Code Examples

### Seed a test issue in memory (agent invocation)

```
# Run via: zeroclaw agent -m "..."
# Prompt content:
Call memory_store to file a sentinel verification test:
memory_store("issue:2026-03-04T00:00:00Z", "TEST: Sentinel verification — seeded entry | type: test | priority: low | status: unresolved")
```

### Trigger sentinel manually for live test

```bash
zeroclaw agent -m "Run the sentinel skill — scan ZeroClaw memory for unresolved issues and trigger repair-loop for each. Escalate to Enrique via WhatsApp if any repair fails."
```

### Clean up seeded issue after test

```
# Run via: zeroclaw agent -m "..."
memory_store("issue:2026-03-04T00:00:00Z:resolved", "Sentinel verification test complete — entry cleaned up 2026-03-05")
```

### Verify sentinel cron is still registered

```bash
zeroclaw cron list
# Expected: shows job ID 1f80a4ae-da3c-4498-a6d6-637fc7aed082 with schedule "0 */2 * * *"
```

### Redeploy sentinel skill after SKILL.md update

```bash
cd /etc/nixos/zeroclaw
zeroclaw skills audit ./skills/sentinel
zeroclaw skills install ./skills/sentinel
zeroclaw skills list | grep sentinel
git add skills/sentinel/SKILL.md
git commit -m "fix(skills): correct sentinel memory scan pattern based on live test results"
```

### Generate Phase 3 VERIFICATION.md frontmatter

```markdown
---
phase: 03-self-modification-and-resilience
verified: 2026-03-05T00:20:00Z
status: passed
score: 6/6 must-haves verified
---
```

### Update VALIDATION.md frontmatter for sign-off

```yaml
# Change from:
status: draft
nyquist_compliant: false
wave_0_complete: false

# Change to:
status: complete
nyquist_compliant: true
wave_0_complete: true
```

### skills/README.md patch — additional constraint text

The following text should be added after the existing "no symlinks" Important block (line 40-42):

```markdown
Shell script files (`.sh`) also cannot be placed inside skill packages — the `zeroclaw skills audit` security policy rejects them. Scripts invoked by skill tools must live **outside** the skill directory. The established pattern is `/etc/nixos/zeroclaw/bin/<script>.sh`. Reference scripts via absolute path in the SKILL.toml `command` field.
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| RPR-03 partially satisfied (documented but unverified) | RPR-03 fully closed (documented + live end-to-end test passed) | Phase 4 closes this gap |
| Phase 3 VALIDATION.md: draft, nyquist_compliant: false | Phase 3 VALIDATION.md: complete, nyquist_compliant: true | After Phase 4 sign-off |
| Phase 3 VERIFICATION.md: missing | Phase 3 VERIFICATION.md: generated and committed | New artifact from Phase 4 |
| skills/README.md: no-symlinks documented, .sh restriction undocumented | skills/README.md: both restrictions documented | Single-sentence addition |

---

## Open Questions

1. **Does `memory_recall("issue:")` perform prefix scan or exact match?**
   - What we know: CLI `memory get` is exact-key only. Agent tool behavior is separate. Phase 3 flagged this LOW confidence.
   - What's unclear: Whether ZeroClaw's agent tool API implements prefix scan or requires an exact key.
   - Recommendation: The live test in Task 1 resolves this definitively. If prefix scan fails, update sentinel SKILL.md before signing off RPR-03.

2. **How to clean up the seeded test issue after live test?**
   - What we know: `memory_store("issue:<ts>:resolved", ...)` is the established resolution pattern for sentinel logic.
   - What's unclear: Whether `zeroclaw memory clear --key <key>` CLI syntax exists and can delete individual entries.
   - Recommendation: Use `memory_store("issue:...:resolved", ...)` in an agent session as the cleanup method — this is the canonical pattern the sentinel checks for anyway. The sentinel will then correctly skip it in future runs.

3. **Does the sentinel cron job still exist? (ID: 1f80a4ae-da3c-4498-a6d6-637fc7aed082)**
   - What we know: It was registered in Phase 3-03. The live `zeroclaw cron list` output from this research session confirmed it: next run 2026-03-05T02:00:00+00:00, schedule `0 */2 * * *`.
   - What's unclear: Nothing — this is confirmed.
   - Recommendation: First task action should be `zeroclaw cron list` to confirm cron is still registered before running the live test.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Manual + CLI verification (no automated test suite) |
| Config file | None — behavioral/documentation phase |
| Quick run command | `zeroclaw cron list && zeroclaw skills list \| grep sentinel` |
| Full suite command | `zeroclaw cron list && zeroclaw skills list && zeroclaw memory list && git log --oneline -5` |
| Estimated runtime | ~15 seconds |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RPR-03 | memory_recall("issue:") prefix scan confirmed and sentinel detects seeded issue | Live agent test | `zeroclaw agent -m "Run the sentinel skill..."` (observe output) | ✅ sentinel SKILL.md exists |
| RPR-03 | Phase 3 VERIFICATION.md committed | File check | `ls .planning/phases/03-self-modification-and-resilience/03-VERIFICATION.md` | ❌ Wave 0 |
| RPR-03 | Phase 3 VALIDATION.md nyquist_compliant: true | File audit | `grep "nyquist_compliant" .planning/phases/03-self-modification-and-resilience/03-VALIDATION.md` | ✅ exists, needs update |
| RPR-03 | skills/README.md documents .sh file restriction | Content check | `grep -n "\.sh" /etc/nixos/zeroclaw/skills/README.md` | ✅ exists, needs patch |

### Sampling Rate

- **Per task commit:** `zeroclaw skills list | grep sentinel` (after skill updates), `git log --oneline -3` (after documentation commits)
- **Per wave merge:** Full suite command above
- **Phase gate:** RPR-03 fully verified + all 5 success criteria from ROADMAP.md true before phase complete

### Wave 0 Gaps

- [ ] `.planning/phases/03-self-modification-and-resilience/03-VERIFICATION.md` — covers RPR-03 Phase 3 documentation debt

*(All other infrastructure (sentinel skill, cron, VALIDATION.md) already exists from Phase 3 — no additional setup needed before implementation)*

---

## Sources

### Primary (HIGH confidence)

- `zeroclaw memory --help` — confirmed CLI subcommands: list (no prefix filter), get (exact key only), stats, clear. No prefix scan available from shell.
- `zeroclaw cron list` (live) — confirmed sentinel cron registered: ID `1f80a4ae-da3c-4498-a6d6-637fc7aed082`, schedule `0 */2 * * *`, next: 2026-03-05T02:00:00+00:00
- `/etc/nixos/zeroclaw/skills/sentinel/SKILL.md` — confirmed current SKILL.md uses `memory_recall("issue:")` prefix pattern; Enrique's number embedded directly
- `/etc/nixos/zeroclaw/.planning/phases/03-self-modification-and-resilience/03-VALIDATION.md` — confirmed current state: `nyquist_compliant: false`, `status: draft`, all tasks pending
- `/etc/nixos/zeroclaw/.planning/phases/03-self-modification-and-resilience/03-UAT.md` — confirmed Phase 3 UAT: 6/6 tests passed, all requirements satisfied
- `/etc/nixos/zeroclaw/.planning/phases/03-self-modification-and-resilience/03-03-SUMMARY.md` — confirmed cron job decision: .sh restriction discovered during Phase 3 Plan 02 execution
- `/etc/nixos/zeroclaw/skills/README.md` — confirmed current text: symlink restriction documented, .sh restriction NOT documented (the gap)
- `/home/hybridz/.claude/get-shit-done/templates/verification-report.md` — GSD VERIFICATION.md format confirmed

### Secondary (MEDIUM confidence)

- `.planning/phases/03-self-modification-and-resilience/03-RESEARCH.md` — Phase 3 open question on `memory_recall` prefix scan behavior documented as unresolved (Tertiary confidence in Phase 3)
- `zeroclaw memory list` (live) — 5 entries, all in `conversation` category. No `issue:` keys currently in memory. Confirms clean state for seeded live test.

### Tertiary (LOW confidence)

- `memory_recall("issue:")` prefix scan behavior — not verified by CLI or official docs. Must be confirmed at runtime in Phase 4 live test. This is THE critical unknown for RPR-03 closure.

---

## Metadata

**Confidence breakdown:**
- Sentinel infrastructure state (cron registered, skill installed): HIGH — confirmed via live CLI commands during research
- memory_recall prefix scan behavior: LOW — explicitly unverified, requires live agent test
- Phase 3 documentation gap (VERIFICATION.md missing): HIGH — confirmed file does not exist
- VALIDATION.md sign-off state: HIGH — confirmed `nyquist_compliant: false`, tasks pending
- skills/README.md gap: HIGH — confirmed .sh restriction undocumented, text read directly

**Research date:** 2026-03-04
**Valid until:** 2026-04-04 (ZeroClaw CLI stable; memory_recall agent tool behavior subject to runtime validation)
