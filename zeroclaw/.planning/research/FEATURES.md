# Feature Research

**Domain:** Autonomous personal AI agent infrastructure (chief-of-staff)
**Researched:** 2026-03-04
**Confidence:** HIGH — based on live config reference, prior system architecture (OpenClaw summary), and existing ZeroClaw deployment

## Feature Landscape

### Table Stakes (Users Expect These)

Features Kiro must have to function as a chief-of-staff agent. Missing any of these means the agent cannot operate autonomously.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Identity document system (IDENTITY, SOUL, AGENTS, USER, LORE, TOOLS) | Agent has no personality or operational directives without it — it's the brain | LOW | 6 documents, all exist in `/etc/nixos/zeroclaw/documents/`. Live-editable via `mkOutOfStoreSymlink`. Already deployed. |
| WhatsApp channel (Kapso bridge) | Primary communication interface with Enrique — without it the agent is deaf and mute | HIGH | Already deployed via `kapso-whatsapp-plugin`. Allowlist of 4 numbers. Voice note transcription via local Whisper (Spanish). |
| ZeroClaw gateway daemon | The runtime that everything runs through — no daemon, no agent | MEDIUM | Systemd user service `zeroclaw-gateway` already configured. Port 42617, loopback only, pairing disabled for localhost trust. |
| Approval gate enforcement | Agent with outbound capability but no gate is a liability — it must ask before acting externally | LOW | Documented in AGENTS.md. Hard limits defined. Implemented as behavioral rules (not a runtime hook like OpenClaw had). |
| Cron job system | Scheduled tasks are the agent's heartbeat — without them, Kiro only reacts, never initiates | MEDIUM | ZeroClaw has native cron. YAML job definitions in `cron/jobs/`. `cron-sync` script syncs to gateway. No jobs currently migrated. |
| Task queue (persistent work tracker) | Context resets between sessions — the queue is the only durable record of work across sessions | MEDIUM | `task-queue` skill from OpenClaw. Needs porting or replacement with ZeroClaw-native equivalent. |
| Web search capability | Agent cannot research jobs, companies, papers, or trends without web access | LOW | Already configured: `[web_search] enabled = true, provider = "brave"`. Brave Search API wired. |
| Web reader / browser | Agent needs to read full pages, not just search snippets — job descriptions, articles, docs | LOW | Already configured: `[browser] enabled = true, backend = "kiro-browser"`. Chrome profile dedicated to agent. |
| Autonomy config (supervised mode, allowed commands) | Without proper autonomy config, agent either can't run shell commands or runs unconstrained | MEDIUM | Currently only basic config in `module.nix`. Needs `[autonomy]` section with `allowed_commands`, `allowed_roots`, and `workspace_only = false` for cross-repo access. |
| Model routing (zai, zai-coding) | ZeroClaw needs to know which provider and model to call — wrong wire API = 404 errors | LOW | Already configured: `zai` and `zai-coding` providers with `chat_completions` wire API. MEMORY.md confirms `openai-responses` returns 404. |
| Memory / state persistence | Agent forgets everything between sessions without memory — preferences, past work, context | MEDIUM | Not yet configured. ZeroClaw supports `sqlite`, `lucid`, `markdown`, `none` backends. SQLite is the right default. |
| Self-repair protocol | Broken tools during cron runs will silently fail without a self-repair mandate | LOW | Documented in AGENTS.md. Behavioral instruction, not infrastructure — Kiro files issues, attempts fixes, reports. |

### Differentiators (Competitive Advantage)

Features that elevate Kiro from a basic chatbot to a genuine chief-of-staff that operates proactively and grows over time.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Self-modifying identity docs | Kiro updates its own SOUL, AGENTS, LORE, TOOLS as it learns preferences — no manual maintenance | LOW | Infrastructure is ready (symlinks). Behavioral instruction in AGENTS.md. Missing: a workflow hook or convention to gate doc changes through Enrique's approval before commit. |
| Proactive trigger system | Kiro surfaces hot job leads, trending topics, stale tasks without waiting for scheduled time — acts on urgency | MEDIUM | Documented in AGENTS.md. Requires a running gateway listening for inbound events + defined trigger conditions. Currently behavioral, not infrastructure-enforced. |
| Model routing by task type (query classification) | Heavy tasks use `zai` (reasoning), fast tasks use `zai-coding` (code). Right model for right job = cost and quality optimization | MEDIUM | ZeroClaw `[query_classification]` and `[[model_routes]]` support this. Not yet configured in `module.nix`. |
| Sub-agent delegation | Delegate research, code review, or summarization to a specialized sub-agent with limited tool scope | HIGH | ZeroClaw `[agents.<name>]` with `agentic = true` + `allowed_tools` scoping. Not configured. Enables isolating risky operations. |
| Git-first self-modification | All Kiro changes go through git — auditability, rollback, no ad-hoc runtime drift | LOW | Architecture decision already made. Kiro edits in `/etc/nixos/zeroclaw/`, commits via `gpush`. Symlinks ensure changes are live immediately. |
| Observability (runtime traces) | Debugging cron failures, malformed tool calls, and model output issues requires structured trace logs | LOW | ZeroClaw supports `[observability]` with `runtime_trace_mode = "rolling"`. Currently set to `none`. Worth enabling for debugging. |
| Cost tracking and daily limits | With autonomous cron jobs running all day, unchecked API spend is a risk | LOW | `[cost]` section in ZeroClaw config. `enabled = false` by default. Should be enabled with a daily limit once traffic volume is known. |
| Voice note support (bilingual) | Enrique communicates in Spanish casually — voice notes in Spanish are transcribed locally via Whisper | MEDIUM | Already deployed in Kapso config (`transcribe.provider = "local"`, model at `~/ggml-base.bin`, `language = "es"`). This is a significant UX differentiator for a personal agent. |
| OTP gating for sensitive actions | Shell execution, browser open, file writes gated behind TOTP — protection against prompt injection / runaway autonomy | HIGH | ZeroClaw `[security.otp]` supports this. Not configured. High value for a system with WhatsApp as an input channel (untrusted text input surface). |
| Session isolation per WhatsApp number | Each allowed number gets its own conversation context — prevents cross-contamination | LOW | Already deployed via `sessionIsolation = true` in Kapso config. |
| Cron jobs as LLM agent sessions | Every scheduled job is a full agent run, not a script — agent applies judgment, uses tools, handles failures | MEDIUM | This is ZeroClaw's native model. Replaces OpenClaw's YAML-prompt-based cron sessions. 13 jobs to migrate. |
| Skill system (reusable CLI tools) | Repetitive tasks get formalized as typed, tested CLI tools with JSON output — not ad-hoc shell scripts | HIGH | ZeroClaw `SKILL.toml` manifest system. OpenClaw had 7 skills (job-scanner, job-tracker, task-queue, rss-reader, git-activity, track-price-drops, cron-manager). Need to port or rebuild under ZeroClaw conventions. |
| Emergency stop (estop) | Hard-stop switch that persists across restarts — kill-switch for runaway agent behavior | LOW | ZeroClaw `[security.estop]` supports this. Not configured. Prudent safety rail for a fully-autonomous system. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Unrestricted shell access (`allowed_commands = "*"`) | Seems convenient — agent can do anything | Opens prompt injection attacks via WhatsApp; a malicious message could cause arbitrary command execution | Explicit allowlist of needed commands in `[autonomy]`. Expand incrementally. |
| Multi-agent IPC (agents talking to each other) | Sounds powerful — Kiro coordinates with other agents | Adds coordination complexity and blast radius before single-agent is stable. ZeroClaw's `[agents_ipc]` exists but should not be enabled yet | Single-agent first. Delegate via `[agents.<name>]` sub-agents when needed for scoped tasks. |
| Public gateway bind (`allow_public_bind = true`) | Seems needed for webhooks | Exposes the agent runtime to the internet; Kapso handles the external surface via Tailscale delivery mode | Keep gateway on loopback (`127.0.0.1`). Kapso bridge already handles external delivery. |
| Ad-hoc scripts as cron replacements | Faster to write a Python script than create a YAML job | Creates parallel infrastructure, bypasses agent judgment, impossible to audit, breaks self-repair chain | Always use ZeroClaw native cron. The YAML job runs as a full agent session. |
| Writing state files directly (bypassing task-queue) | Seems simpler for quick task tracking | Survives one session, then gets lost. Can't be processed by the task worker cron. Can't be queried or resolved. | Always use `task-queue add`. The queue is the durable record of truth. |
| WASM runtime for skills | Sandbox isolation sounds good | Adds build complexity; `reject_symlink_modules = true` by default blocks our `mkOutOfStoreSymlink` live-editing pattern | Native runtime + explicit `[autonomy]` command allowlist achieves the safety goal without breaking live-edit workflow. |
| Open skills (community registry) | Free skills from the community | Unvetted skills are a supply chain risk on a personal agent with shell access and WhatsApp | Keep `open_skills_enabled = false`. Build private skills in `/etc/nixos/zeroclaw/skills/`. |
| Replying to all WhatsApp group messages | Agent in groups sounds useful | Noisy, high-risk surface, hard to moderate | Keep `allowed_numbers` to explicit allowlist. No group participation. |

## Feature Dependencies

```
[WhatsApp channel]
    └──requires──> [ZeroClaw gateway daemon]
                       └──requires──> [Model provider config (zai)]
                                          └──requires──> [Secrets (zeroclaw.env)]

[Cron jobs]
    └──requires──> [ZeroClaw gateway daemon]
    └──requires──> [Skills (job-scanner, rss-reader, task-queue, etc.)]
                       └──requires──> [Task queue]

[Proactive triggers]
    └──requires──> [Cron job system] (for session context)
    └──requires──> [WhatsApp channel] (for outbound notification)

[Self-modifying identity docs]
    └──requires──> [Git-first workflow] (for auditability)
    └──enhances──> [Identity document system]

[Sub-agent delegation]
    └──requires──> [Model routing (query classification)]
    └──enhances──> [Cron jobs] (delegate heavy research to sub-agent)

[OTP gating]
    └──requires──> [Security.otp config]
    └──enhances──> [WhatsApp channel] (gates shell/browser from untrusted input)

[Cost tracking]
    └──enhances──> [Model routing] (tracks spend per route)

[Observability (runtime traces)]
    └──enhances──> [Cron jobs] (post-mortem for failures)
    └──enhances──> [Self-repair protocol] (structured evidence for what broke)

[Emergency stop]
    └──enhances──> [ZeroClaw gateway daemon] (persisted kill-switch)
```

### Dependency Notes

- **WhatsApp channel requires ZeroClaw gateway:** The Kapso bridge connects to the gateway WebSocket (`ws://127.0.0.1:42617/ws/chat`). No gateway = no WhatsApp.
- **Cron jobs require skills:** The 13 scheduled jobs each invoke specific skills (`job-scanner`, `rss-reader`, `task-queue`, etc.). Jobs should not be migrated until their required skills are available.
- **Proactive triggers require both cron and WhatsApp:** The agent needs an active session context (from cron) to detect conditions, and a channel to fire the notification through.
- **OTP gating enhances WhatsApp security:** WhatsApp is an untrusted text input surface. Gating shell and browser_open behind TOTP protects against prompt injection before shell access is approved.
- **Sub-agent delegation should come after single-agent is stable:** Adding delegation complexity before the primary agent is reliable creates debugging hell.

## MVP Definition

### Launch With (v1 — Infrastructure Phase)

Minimum configuration for Kiro to be operational and safe. No job migration yet.

- [x] ZeroClaw gateway daemon (already deployed)
- [x] WhatsApp channel via Kapso bridge (already deployed)
- [x] Identity documents: IDENTITY, SOUL, AGENTS, USER, TOOLS, LORE (already deployed, need content audit)
- [x] Web search (Brave) + browser (kiro-browser) (already configured)
- [x] Model providers: zai + zai-coding with `chat_completions` (already configured)
- [ ] `[autonomy]` section: `allowed_commands` allowlist, `allowed_roots` for `~/Projects/` and `/etc/nixos/`, `workspace_only = false`
- [ ] `[memory]` section: `backend = "sqlite"`, `auto_save = true`
- [ ] `[observability]`: `runtime_trace_mode = "rolling"` for debugging early issues
- [ ] `[security.estop]`: enabled with `require_otp_to_resume = true` as a safety rail
- [ ] Upstream docs symlink: `reference/upstream-docs/` → `~/Projects/zeroclaw/docs/`
- [ ] CLAUDE.md for this directory (LLM agents working on the infra need it)

### Add After Validation (v1.x — Jobs + Skills Phase)

After the infrastructure is confirmed stable and Kiro can operate interactively.

- [ ] Task queue skill (port from OpenClaw or build native) — required before any cron job
- [ ] Core cron jobs: morning-briefing, end-of-day, task-worker (minimum viable schedule)
- [ ] Job scanning skills: job-scanner, job-tracker — enables income priority
- [ ] RSS / research skills: rss-reader, git-activity — enables content and skill-scan jobs
- [ ] Remaining 10 cron jobs migrated and tested
- [ ] `[cost]` tracking enabled with a daily limit (after traffic volume is known)

### Future Consideration (v2+ — Intelligence Phase)

After core jobs are running reliably.

- [ ] `[query_classification]` + `[[model_routes]]` — smart model routing by task type. Defer until token costs are a real concern.
- [ ] Sub-agent delegation (`[agents.researcher]`, `[agents.coder]`) — once delegation patterns are identified from cron job usage.
- [ ] `[security.otp]` for shell/browser actions — add if prompt injection risk materializes from WhatsApp exposure.
- [ ] `track-price-drops` skill (BTC monitoring) — currently a stub in OpenClaw, low priority.
- [ ] Nostr channel — alternative communication channel if WhatsApp reliability becomes an issue.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Autonomy config (`[autonomy]` section) | HIGH | LOW | P1 |
| Memory persistence (SQLite) | HIGH | LOW | P1 |
| Runtime trace observability | HIGH | LOW | P1 |
| Emergency stop | HIGH | LOW | P1 |
| Upstream docs symlink + CLAUDE.md | HIGH | LOW | P1 |
| Task queue skill | HIGH | MEDIUM | P1 |
| Core cron jobs (briefing, EOD, task-worker) | HIGH | MEDIUM | P1 |
| Job-scanner + job-tracker skills | HIGH | MEDIUM | P2 |
| RSS-reader + git-activity skills | MEDIUM | MEDIUM | P2 |
| Remaining 10 cron jobs | MEDIUM | MEDIUM | P2 |
| Cost tracking | MEDIUM | LOW | P2 |
| Query classification + model routes | MEDIUM | MEDIUM | P3 |
| Sub-agent delegation | MEDIUM | HIGH | P3 |
| OTP gating for shell/browser | MEDIUM | MEDIUM | P3 |
| track-price-drops skill | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch (infrastructure phase)
- P2: Should have, add when possible (jobs + skills phase)
- P3: Nice to have, future consideration (intelligence phase)

## Competitor Feature Analysis

This is a personal agent system, not a product. "Competitors" are prior versions and alternative architectures.

| Feature | OpenClaw (prior system) | Generic AI Chatbot | Kiro / ZeroClaw Approach |
|---------|------------------------|---------------------|--------------------------|
| Cron scheduling | Custom YAML + Go gateway + cron-sync | None | Native ZeroClaw cron (no custom sync infra) |
| Self-modification | 4-layer system (hooks, self-repair, skill creation, doc editing) | None | Git-first edits with symlinks for live-reload |
| Skill system | Bun/TypeScript CLI tools | None | ZeroClaw SKILL.toml manifests |
| Approval gates | Plugin hooks (intent-detector + tool-guard) | None | Behavioral (AGENTS.md) — ZeroClaw may support hooks later |
| Communication | WhatsApp via Kapso | Web UI | WhatsApp via Kapso (same) |
| Memory | Not documented | Session-only | SQLite via ZeroClaw native memory |
| Tool guardrails | PreToolUse hook blocking ad-hoc scheduling | None | Behavioral (AGENTS.md) + `[autonomy]` config |
| Observability | Not documented | None | ZeroClaw runtime traces + OTLP |
| Security | Plugin-level hooks | None | `[security.otp]` + `[security.estop]` + syscall anomaly detection |

Key takeaway: ZeroClaw provides most of what required custom plugin infrastructure in OpenClaw — natively. The skill system is different (SKILL.toml vs SKILL.md + run.ts) but the concept is the same. The main gap is the approval gate enforcement: OpenClaw had hard PreToolUse hooks; ZeroClaw relies on behavioral instructions in AGENTS.md. This is a deliberate tradeoff (less infra, but also less enforcement).

## Sources

- `/home/hybridz/Projects/zeroclaw/docs/config-reference.md` — ZeroClaw config schema, verified February 25, 2026 (HIGH confidence)
- `/etc/nixos/openclaw/summary.md` — OpenClaw architecture reference for feature requirements (HIGH confidence — first-hand system)
- `/etc/nixos/zeroclaw/module.nix` — Current deployment state (HIGH confidence — live config)
- `/etc/nixos/zeroclaw/documents/AGENTS.md` and `TOOLS.md` — Behavioral requirements and tool inventory (HIGH confidence)
- `/etc/nixos/zeroclaw/.planning/PROJECT.md` — Project scope and constraints (HIGH confidence)

---
*Feature research for: ZeroClaw autonomous agent infrastructure (Kiro)*
*Researched: 2026-03-04*
