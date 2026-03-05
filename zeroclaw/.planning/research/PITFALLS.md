# Pitfalls Research

**Domain:** Autonomous AI agent infrastructure on NixOS (ZeroClaw / Kiro)
**Researched:** 2026-03-04
**Confidence:** HIGH — derived from first-hand OpenClaw post-mortem, official ZeroClaw config-reference (verified Feb 25 2026), and ZeroClaw engineering principles document

---

## Critical Pitfalls

### Pitfall 1: Wrong Provider API Type Silently Returns 404

**What goes wrong:**
The Z.AI provider (custom endpoint) returns `404 Not Found` for all requests. The agent appears to start but every model call fails. This is not a network or auth error — it's a config error that looks like an outage.

**Why it happens:**
ZeroClaw supports two API wire protocols for custom providers: `openai-chat-completions` and `openai-responses`. The default assumption may be `openai-responses`, but Z.AI only implements the `openai-chat-completions` (Chat Completions) surface. This is a known incompatibility documented in project memory.

**How to avoid:**
Set `provider_api = "openai-chat-completions"` explicitly in config.toml for the Z.AI custom provider. Never leave `provider_api` unset when using a non-OpenAI custom endpoint. Validate with `zeroclaw doctor` after any provider config change.

**Warning signs:**
- Every agent response is an error; no successful model call in logs
- `zeroclaw doctor` reports provider unreachable
- HTTP 404 in observability/trace logs

**Phase to address:** Phase 1 (Config foundation) — provider config must be validated before any other work proceeds.

---

### Pitfall 2: Editing `~/.zeroclaw/` Directly Instead of `/etc/nixos/zeroclaw/`

**What goes wrong:**
Changes made directly in `~/.zeroclaw/` are silently overwritten on the next `nixos-rebuild switch`. The single source of truth is `/etc/nixos/zeroclaw/` — `~/.zeroclaw/` is a deployment target, never an editor's workspace. Any manual edit there is lost.

**Why it happens:**
`~/.zeroclaw/config.toml` is the file ZeroClaw reads at runtime. It's the natural place to "just fix something quickly." The NixOS indirection is non-obvious to anyone unfamiliar with the deployment model, including Kiro itself if not explicitly instructed.

**How to avoid:**
- Document in CLAUDE.md and AGENTS.md that `~/.zeroclaw/` is read-only from Kiro's perspective.
- Kiro's self-modification workflow must always target `/etc/nixos/zeroclaw/`.
- For live-editable paths (docs/, skills/, cron/), use `mkOutOfStoreSymlink` so edits in `/etc/nixos/zeroclaw/` are immediately visible at `~/.zeroclaw/` without a rebuild.
- For structural config changes, commit to git and run `sudo nixos-rebuild switch`.

**Warning signs:**
- Kiro reports making a change but it "doesn't stick" after next rebuild
- Config reverts unexpectedly after system update
- Kiro editing files under `~/.zeroclaw/` in bash tool calls

**Phase to address:** Phase 1 (Config foundation + module.nix symlink wiring).

---

### Pitfall 3: `allowed_commands` Not Set Causes Silent Shell Tool Failure

**What goes wrong:**
With `autonomy.level = "supervised"` or `"full"`, shell tool calls fail silently or are rejected if `allowed_commands` is not explicitly populated. The error is not obvious — the agent may think the command ran when it was actually blocked by policy.

**Why it happens:**
`allowed_commands` is required for shell execution per the config-reference. It has no safe default — an empty list means no commands are allowed. Operators building config from scratch often miss this because the key's absence looks like "default to permissive," but ZeroClaw's secure-by-default posture means the opposite.

**How to avoid:**
Always define `allowed_commands` explicitly. For Kiro's use case: `["git", "zeroclaw", "bash", "cat", "ls", "grep", "find", "jq", "curl"]` at minimum. Expand from there based on actual skill needs. Use `zeroclaw doctor` to validate the autonomy policy after config changes.

**Warning signs:**
- Skills that invoke shell commands return empty output or generic errors
- Agent reports tool call succeeded but no side effects occurred
- `zeroclaw doctor` reports autonomy policy warnings

**Phase to address:** Phase 1 (Config foundation — autonomy section).

---

### Pitfall 4: `forbidden_paths` Does Not Cover NixOS-Specific Sensitive Paths

**What goes wrong:**
The built-in `forbidden_paths` list covers standard Unix paths (`/etc`, `/root`, `/proc`, `/sys`, `~/.ssh`, `~/.gnupg`, `~/.aws`) but does not include NixOS-specific sensitive locations. Kiro could read or modify sops secrets, age keys, or nix store paths that should be protected.

**Why it happens:**
ZeroClaw's default forbidden_paths is designed for generic Linux. NixOS has additional sensitive paths not in the default list: sops secrets at `/run/secrets/`, age private keys at `~/.config/sops/age/keys.txt`, and the nix store at `/nix/store/`.

**How to avoid:**
Extend `forbidden_paths` in config.toml to add NixOS-specific paths:
```toml
[autonomy]
forbidden_paths = [
  "/etc", "/root", "/proc", "/sys",
  "~/.ssh", "~/.gnupg", "~/.aws",
  "/run/secrets",
  "~/.config/sops",
  "/nix/store"
]
```

**Warning signs:**
- Kiro attempting to read files under `/run/secrets/` in tool call logs
- Runtime traces showing file_read attempts on age key paths

**Phase to address:** Phase 1 (Config foundation — security section).

---

### Pitfall 5: Self-Modification Without Git Commit Breaks Auditability

**What goes wrong:**
Kiro edits files in `/etc/nixos/zeroclaw/` but skips the git commit step. The change is live but untracked. The next `nixos-rebuild switch` may or may not pick it up depending on what changed. More importantly, rollback becomes impossible and the git history becomes unreliable.

**Why it happens:**
The self-modification workflow has multiple steps: edit → commit → rebuild (if needed). When Kiro is in a hurry or a skill fails partway through, the commit step may be skipped. Without an enforcement mechanism, this will happen.

**How to avoid:**
- Document the self-modification workflow explicitly in AGENTS.md: edit → `git add` → `git commit` → rebuild only if .nix files changed.
- Consider having Kiro's self-repair protocol always check `git status` before reporting a fix complete.
- The task-queue "resolve" step should only run after the commit is confirmed.

**Warning signs:**
- `git status` in `/etc/nixos/zeroclaw/` shows uncommitted modifications
- Kiro reports a fix as complete but `git log` doesn't show the corresponding commit
- Config divergence between working tree and HEAD

**Phase to address:** Phase 2 (Self-modification workflow documentation in AGENTS.md).

---

### Pitfall 6: `phone_number_id` as Bare Number Breaks YAML/TOML Parsing

**What goes wrong:**
The WhatsApp Kapso bridge's `phone_number_id` is a large integer (e.g. `123456789012345`). When written as a bare value in YAML (for sops secrets) or TOML (for config), some parsers interpret it as an integer and silently truncate or mishandle it. The Kapso API expects a string, so requests fail with authentication or routing errors.

**Why it happens:**
This is a known project gotcha documented in MEMORY.md from the OpenClaw era. Large phone number IDs exceed JavaScript's safe integer range. YAML's type inference treats bare numbers as integers. The fix is to quote the value explicitly: `phone_number_id: "123456789012345"`.

**How to avoid:**
Always quote `phone_number_id` (and any similar large numeric ID) in both the sops secrets YAML and anywhere it appears in config. Document this in TROUBLESHOOTING.md.

**Warning signs:**
- WhatsApp channel fails to authenticate
- Kapso API returns 400/401 errors
- `zeroclaw channel doctor` shows WhatsApp channel in error state

**Phase to address:** Phase 1 (Config foundation — channels_config.whatsapp section).

---

### Pitfall 7: `max_tool_iterations` Too Low for Autonomous Cron Sessions

**What goes wrong:**
The default `max_tool_iterations = 20` is appropriate for interactive chat but too low for autonomous cron sessions that involve multiple tool calls (web scraping, file reads, memory writes, git operations, WhatsApp messages). Sessions hit the cap mid-task and return "Agent exceeded maximum tool iterations" to the cron channel — not the user. The cron job silently fails.

**Why it happens:**
The default was designed for supervised interactive use where the user is waiting. Autonomous cron sessions with complex workflows (e.g. "scan job boards, filter results, update job-tracker, send summary") easily exceed 20 tool iterations.

**How to avoid:**
Set `max_tool_iterations` higher for autonomous operation. Based on OpenClaw's most complex jobs (job-scan involves ~30 tool calls per run), a value of `50-80` is appropriate. Monitor runtime traces to calibrate.

**Warning signs:**
- Cron sessions frequently end with "exceeded maximum tool iterations" in logs
- Cron job output is truncated or partial
- Tasks appear half-done in the job tracker or task queue

**Phase to address:** Phase 1 (Config foundation — agent section), revisit in Phase 3 (Cron job migration).

---

### Pitfall 8: Symlink Security Blocks `skills/` Directory

**What goes wrong:**
ZeroClaw's skill loading security audit rejects symlinked files. If `skills/` is wired via `mkOutOfStoreSymlink` (pointing to `/etc/nixos/zeroclaw/skills/`), ZeroClaw may reject skills with "symlink detected" errors at load time, since the default WASM runtime security config has `reject_symlink_tools_dir = true`.

**Why it happens:**
ZeroClaw's WASM runtime security defaults are conservative. `reject_symlink_modules = true` blocks individual symlinked `.wasm` files, and `reject_symlink_tools_dir = true` blocks the entire tools directory if it's a symlink. The NixOS `mkOutOfStoreSymlink` pattern creates real symlinks, which triggers this protection.

**How to avoid:**
For the WASM runtime, do not symlink the entire tools_dir — copy or generate files into a real (non-symlinked) path. For non-WASM skills (ZeroClaw's native SKILL.toml skills), verify whether the same restriction applies by testing with `zeroclaw skills list` after symlink wiring. If blocked, adjust the wiring strategy: symlink individual files rather than the directory, or use a different path mapping in module.nix.

**Warning signs:**
- `zeroclaw skills list` returns empty or errors after home-manager rebuild
- Skills that were previously available stop loading after a config change
- ZeroClaw startup logs mention "symlink rejected" for skills directory

**Phase to address:** Phase 1 (module.nix symlink design) — must be validated before Phase 3 (skills scaffolding).

---

### Pitfall 9: OpenClaw Custom Infrastructure Patterns Applied to ZeroClaw

**What goes wrong:**
Building custom hook scripts, cron-sync tools, YAML-based job definitions with external sync, or plugin manifests — replicating the OpenClaw architecture in ZeroClaw instead of using ZeroClaw's native systems. This creates parallel infrastructure that fights ZeroClaw's design.

**Why it happens:**
OpenClaw required extensive custom infrastructure because it lacked native cron, skills, and autonomy controls. ZeroClaw provides all of these natively. The temptation is to copy what worked before without questioning whether it's still necessary.

**How to avoid:**
- Cron: use ZeroClaw's native cron system (SKILL.toml or cron config), not YAML + cron-sync
- Skills: use ZeroClaw's SKILL.toml manifest format, not OpenClaw's SKILL.md + run.ts pattern
- Workflow enforcement: use ZeroClaw's autonomy config (allowed_commands, auto_approve, always_ask), not custom hook scripts
- Plugin system: not needed — ZeroClaw handles extension natively through config
- Before building any custom tool, check if ZeroClaw's config-reference already covers the need

**Warning signs:**
- Any new `.sh` hook script being created
- Replicating `cron-sync` logic for pushing jobs to ZeroClaw
- YAML-based job definitions with an external sync step
- Custom plugin.json being created

**Phase to address:** Phase 2 (Architecture documentation and CLAUDE.md for Kiro) — establish clear "use ZeroClaw native" rule before any jobs are built.

---

### Pitfall 10: `allowed_numbers` Empty Means Deny All on WhatsApp

**What goes wrong:**
Setting `channels_config.whatsapp.allowed_numbers = []` (or omitting it) results in all inbound WhatsApp messages being denied. Kiro becomes unreachable via WhatsApp despite the service running and appearing healthy.

**Why it happens:**
ZeroClaw's deny-by-default channel security means an empty allowlist denies all. This is the correct security posture but is counterintuitive — most operators expect "no list" to mean "allow all."

**How to avoid:**
Explicitly set `allowed_numbers = ["<enrique-whatsapp-number>"]` in the WhatsApp channel config. Use the full international format. Never leave this as an empty list in production. Document the number format requirements.

**Warning signs:**
- WhatsApp messages sent to Kiro receive no response
- `zeroclaw channel doctor` shows WhatsApp active but no messages processed
- Gateway logs show inbound messages rejected with "sender not in allowlist"

**Phase to address:** Phase 1 (Config foundation — channels_config section).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Copying all 13 OpenClaw cron jobs as-is | Fast job restoration | Jobs use OpenClaw patterns (YAML+sync) that don't fit ZeroClaw natively; creates maintenance burden | Never — migrate incrementally using ZeroClaw native format |
| Using `allowed_commands = ["*"]` | Removes autonomy friction | Eliminates the entire command-allowlist security layer; hard to tighten later | Never in production; acceptable only for initial config exploration if reverted before first commit |
| Skipping `observability.runtime_trace_mode` | Simpler config | Blind to tool-call failures and malformed payloads; debugging becomes guesswork | Acceptable in Phase 1 if enabled before cron jobs run |
| Hardcoding model names instead of using `[[model_routes]]` | Fewer config lines | Model upgrades require finding all hardcoded references; breaks query_classification routing | Never — use route hints from Phase 1 |
| Setting `autonomy.level = "full"` without a full `allowed_commands` list | Less approval friction | Broad shell access with no guardrails; undermines the whole autonomy model | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Z.AI (custom endpoint) | Using `openai-responses` API type | Set `provider_api = "openai-chat-completions"` — Z.AI only implements Chat Completions wire |
| Kapso (WhatsApp bridge) | Bare integer for `phone_number_id` in YAML | Always quote: `phone_number_id: "123456789012345"` |
| WhatsApp channel | Empty `allowed_numbers` list | Explicitly list every allowed sender number in E.164 format |
| NixOS home-manager + ZeroClaw | Editing `~/.zeroclaw/` directly | All edits go to `/etc/nixos/zeroclaw/`, then rebuild or rely on symlinks |
| ZeroClaw symlink security + WASM | Symlinking WASM tools_dir | Verify `reject_symlink_tools_dir` behavior; may need non-symlinked path for WASM modules |
| sops secrets injection | Reading secrets from wrong path | Secrets are at `/run/secrets/rendered/zeroclaw.env`; the zsh wrapper loads them before zeroclaw runs |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `max_tool_iterations = 20` for autonomous sessions | Cron jobs silently truncate mid-task | Set to 50-80 for cron autonomy level | First complex cron session (job-scan, morning briefing) |
| `compact_context = false` with local/small models | Slow responses, context exhaustion on Ollama | Set `compact_context = true` for 13B or smaller models | First local-model session with large skill set loaded |
| `message_timeout_secs = 300` with cloud APIs | Unnecessary 5-minute waits on timeout | Reduce to 60 when using Z.AI (cloud) | Every session timeout event |
| Memory `backend = "sqlite"` without embedding provider | Keyword-only memory recall, misses semantic matches | Add embedding provider if semantic memory retrieval is needed | When memory corpus grows beyond ~50 entries |
| Research phase `trigger = "always"` | Every message triggers a research pass before responding | Use `trigger = "keywords"` with a targeted keyword list | Immediately — adds latency to every interaction |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Not extending `forbidden_paths` for NixOS | Kiro reads sops age keys, rendered secrets under `/run/secrets/` | Add `/run/secrets`, `~/.config/sops`, `/nix/store` to forbidden_paths |
| `allow_public_bind = true` on gateway | ZeroClaw gateway exposed to network without auth | Keep `allow_public_bind = false`; bind to 127.0.0.1 only |
| `allowed_numbers = ["*"]` on WhatsApp | Any WhatsApp number can invoke Kiro's full tool set | Always use explicit allowlist; "*" is appropriate only for testing |
| Secrets in config.toml committed to git | API keys, tokens in git history | All secrets via sops; reference `${VARNAME}` in config or use ZeroClaw's encrypted secrets store |
| `security.otp.enabled = false` for shell/file_write | Agent can execute shell and write files without human confirmation | Enable OTP or ensure `always_ask` covers high-risk tools during initial deployment |
| `estop.enabled = false` | No emergency kill switch for runaway autonomous sessions | Enable estop from Phase 1; test `zeroclaw estop` before enabling full autonomy |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Kiro sends WhatsApp messages during testing/debugging | Test runs create real user-facing messages | Use `always_ask = ["channel_send"]` or disable WhatsApp channel during development phases |
| Cron jobs fire before config is validated | Broken session output lands in WhatsApp | Validate all config with `zeroclaw doctor` before enabling first cron job |
| Self-repair reports flood WhatsApp | Every broken tool generates a message to the user | Self-repair should file in task-queue first; only surface to WhatsApp in end-of-day summary |
| Kiro changes AGENTS.md without approval | Behavioral drift without user awareness | Per OpenClaw TOOLS.md precedent: proposed doc edits require approval before applying |
| Over-verbose cron output to WhatsApp | Long walls of text on phone | Set a max character limit for cron session WhatsApp output; link to task-queue for details |

---

## "Looks Done But Isn't" Checklist

- [ ] **Config foundation:** `zeroclaw doctor` passes with zero warnings — not just zero errors. Warnings about missing optional config often predict runtime failures.
- [ ] **Provider:** Run `zeroclaw chat "hello"` and confirm a successful response from Z.AI before claiming provider config is done.
- [ ] **WhatsApp channel:** Send an actual WhatsApp message and receive a response — do not just rely on `zeroclaw channel doctor` passing.
- [ ] **Symlinks:** After `nixos-rebuild switch`, verify symlinked paths in `~/.zeroclaw/` resolve correctly with `ls -la ~/.zeroclaw/docs ~/.zeroclaw/skills`.
- [ ] **Self-modification workflow:** Have Kiro edit a test file in `/etc/nixos/zeroclaw/`, commit it, and verify the commit appears in `git log` before declaring self-modification working.
- [ ] **Cron jobs:** A cron job "installed" in config is not working until it has fired at least once and the output can be seen in logs — timing is easy to misconfigure.
- [ ] **Estop:** Run `zeroclaw estop` and `zeroclaw estop resume` at least once to verify the kill switch works before enabling full autonomy level.
- [ ] **Forbidden paths:** Verify Kiro cannot read `/run/secrets/rendered/zeroclaw.env` via a test file_read tool call — the runtime should block it, not Kiro's self-restraint.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong API type (404 from Z.AI) | LOW | Fix `provider_api` in config.toml, `nixos-rebuild switch`, `zeroclaw doctor` |
| Direct `~/.zeroclaw/` edit overwritten | LOW if caught early, HIGH if significant work lost | Check `git diff` in `/etc/nixos/zeroclaw/`, reconstruct lost changes, commit properly |
| `allowed_commands` not set, skills failing | LOW | Add missing commands to config, rebuild, retest skills |
| Uncommitted self-modifications | LOW | `git add`, `git commit` in `/etc/nixos/zeroclaw/`, then rebuild if needed |
| OpenClaw pattern imported into ZeroClaw | MEDIUM | Identify and replace each custom infrastructure piece with ZeroClaw native equivalent |
| WhatsApp allow_numbers misconfigured | LOW | Fix list, rebuild, test with actual message |
| `max_tool_iterations` too low, jobs failing silently | LOW | Raise value, check observability traces to confirm jobs complete |
| Symlink security blocking skills | MEDIUM | Redesign module.nix wiring, may require rethinking path structure |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Wrong provider API type | Phase 1 (Config) | `zeroclaw chat "hello"` returns successful response |
| Direct `~/.zeroclaw/` editing | Phase 1 (module.nix + CLAUDE.md) | Kiro's first self-modification goes through git |
| `allowed_commands` not set | Phase 1 (Config — autonomy) | Shell tool call succeeds in test session |
| Missing NixOS forbidden_paths | Phase 1 (Config — security) | File read attempt on `/run/secrets/` is blocked |
| Self-modification without git commit | Phase 2 (AGENTS.md workflow docs) | Git log shows every Kiro-initiated change |
| `phone_number_id` integer parsing | Phase 1 (Config — channels) | WhatsApp send/receive test completes |
| `max_tool_iterations` too low | Phase 1 (Config — agent) | Complex cron session (30+ tool calls) completes without truncation |
| Symlink security blocking skills | Phase 1 (module.nix design) | `zeroclaw skills list` shows expected skills after rebuild |
| OpenClaw patterns applied to ZeroClaw | Phase 2 (Architecture docs) | No custom hook scripts, no cron-sync, no plugin.json created |
| `allowed_numbers` empty | Phase 1 (Config — channels) | WhatsApp message from allowed number receives response |

---

## Sources

- `/etc/nixos/openclaw/summary.md` — First-hand OpenClaw post-mortem: architecture, self-modification patterns, hook system, known pitfalls
- `/home/hybridz/Projects/zeroclaw/docs/config-reference.md` — Official ZeroClaw operator config reference (verified Feb 25 2026): security defaults, autonomy model, channel config, WASM security
- `/home/hybridz/Projects/zeroclaw/CLAUDE.md` — ZeroClaw engineering principles: why principles exist reveals past pain points
- `/home/hybridz/.claude/projects/-etc-nixos/memory/MEMORY.md` — Documented session-learned gotchas: Z.AI API type incompatibility, phone_number_id quoting requirement
- `/etc/nixos/zeroclaw/.planning/PROJECT.md` — Project constraints and key decisions

---
*Pitfalls research for: ZeroClaw autonomous agent infrastructure on NixOS*
*Researched: 2026-03-04*
