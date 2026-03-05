# Architecture Research

**Domain:** NixOS-deployed autonomous AI agent infrastructure (ZeroClaw / Kiro)
**Researched:** 2026-03-04
**Confidence:** HIGH

Sources: live `module.nix`, `reference/upstream-docs/config-reference.md`, `reference/upstream-docs/commands-reference.md`, `reference/upstream-docs/operations-runbook.md`, `PROJECT.md`.

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SOURCE OF TRUTH LAYER                           │
│                  /etc/nixos/zeroclaw/  (git-tracked)                │
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │ module.nix  │  │ documents/  │  │   skills/   │  │   cron/   │  │
│  │ (NixOS cfg) │  │ (identity)  │  │ (SKILL.toml)│  │ (YAML)    │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────┬─────┘  │
└─────────┼────────────────┼────────────────┼───────────────┼─────────┘
          │ nixos-rebuild   │ mkOutOfStoreSymlink (live)     │
          ▼                 ▼                ▼               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     DEPLOYMENT LAYER                                │
│                     ~/.zeroclaw/  (generated)                       │
│                                                                     │
│  ┌──────────────────┐  ┌────────────────────────────────────────┐   │
│  │   config.toml    │  │  documents/ → symlink to /etc/nixos/  │   │
│  │  (rendered Nix)  │  │  skills/   → symlink to /etc/nixos/  │   │
│  └──────────────────┘  │  cron/     → symlink to /etc/nixos/  │   │
│                         └────────────────────────────────────────┘   │
└──────────────────────────────────────────┬──────────────────────────┘
                                           │ reads at startup
                                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     RUNTIME LAYER                                   │
│                   zeroclaw daemon (systemd user service)            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │
│  │   Gateway    │  │  Scheduler   │  │   Channel Handlers       │   │
│  │ :42617/ws    │  │ (cron loop)  │  │   CLI / WhatsApp         │   │
│  └──────┬───────┘  └──────────────┘  └──────────────────────────┘   │
│         │                                                            │
│  ┌──────▼───────────────────────────────────────────────────────┐   │
│  │                    Agent Core                                 │   │
│  │  LLM turns → tool dispatch → memory → model routing          │   │
│  └──────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  SQLite memory  │  Runtime traces  │  State files            │    │
│  └─────────────────────────────────────────────────────────────┘    │
└───────────────────────┬─────────────────────────────────────────────┘
                        │ WebSocket /ws/chat
                        ▼
┌──────────────────────────────────────────┐
│          kapso-whatsapp-bridge           │
│   (systemd user service, PartOf gateway) │
│   Kapso API ←→ WA Cloud ←→ ZeroClaw WS  │
└──────────────────────────────────────────┘
                        │
                        ▼ Tailscale delivery mode
               WhatsApp (owner phones)
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| `module.nix` | NixOS home-manager module — builds config.toml, wires systemd services, declares symlinks | NixOS build system, home-manager |
| `documents/` | Kiro's identity at runtime (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) — symlinked, live-editable | ZeroClaw agent core reads on startup |
| `skills/` | SKILL.toml manifests + skill logic — symlinked, live-editable | ZeroClaw skills subsystem |
| `cron/` | YAML/TOML cron job definitions — picked up by ZeroClaw scheduler | ZeroClaw cron subsystem |
| `reference/upstream-docs/` | Symlink to `~/Projects/zeroclaw/docs/` — reference only, not deployed | Human operators, coding agents |
| `config.toml` (rendered) | Structural config — model providers, gateway, autonomy, channels, security | ZeroClaw daemon at startup |
| `zeroclaw-gateway` (systemd) | Persistent daemon — runs gateway + channel handlers + cron scheduler | kapso-whatsapp-bridge (WantedBy) |
| `kapso-whatsapp-bridge` (systemd) | WhatsApp ↔ ZeroClaw relay — PartOf gateway lifecycle | zeroclaw-gateway via WebSocket :42617 |
| `zeroclaw.env` (sops secret) | Runtime secrets injected as env vars | systemd EnvironmentFile |

---

## Recommended Directory Layout

```
/etc/nixos/zeroclaw/           # Source of truth — git tracked
├── module.nix                 # Home-manager module (NixOS config, rebuild-required)
├── documents/                 # Identity documents (live-editable via symlink)
│   ├── IDENTITY.md            # Who Kiro is
│   ├── SOUL.md                # Personality and style
│   ├── AGENTS.md              # Operational directives, approval gates
│   ├── TOOLS.md               # Capability inventory
│   ├── USER.md                # Owner profile
│   └── LORE.md                # Strategy and context
├── skills/                    # Skills (live-editable via symlink)
│   └── <skill-name>/
│       ├── SKILL.toml         # ZeroClaw skill manifest
│       └── ...                # Skill implementation
├── cron/                      # Cron job definitions (live-editable via symlink)
│   └── <job-name>.toml        # or .yaml depending on ZeroClaw cron format
└── reference/                 # Reference material (not deployed)
    └── upstream-docs/         # Symlink → ~/Projects/zeroclaw/docs/

~/.zeroclaw/                   # Deployment target — never edit directly
├── config.toml                # Rendered by NixOS (force = true)
├── documents/                 # Symlinked from /etc/nixos/zeroclaw/documents/
├── skills/                    # Symlinked from /etc/nixos/zeroclaw/skills/
├── cron/                      # Symlinked from /etc/nixos/zeroclaw/cron/
├── state/                     # Runtime state (sqlite memory, traces, daemon state)
│   ├── memory.db
│   ├── runtime-trace.jsonl
│   └── daemon_state.json
└── .download-policy.toml      # Skill trust decisions (runtime-managed)
```

### Structure Rationale

- **documents/:** Identity is the highest-frequency edit target. Symlinked so Kiro can self-modify without triggering a NixOS rebuild.
- **skills/:** Skills grow incrementally. Symlinked so Kiro can scaffold and deploy new skills without rebuild.
- **cron/:** Job definitions change frequently (add/edit/remove jobs). Symlinked for the same reason.
- **module.nix:** The only file that requires `nixos-rebuild switch`. Contains structural config (model providers, gateway port, channel wiring, service declarations). Changes here are intentionally infrequent.
- **reference/upstream-docs/:** Not deployed to `~/.zeroclaw/`. Kept in source tree as a symlink to the live ZeroClaw docs repo — any agent working in this codebase can read them.

---

## Architectural Patterns

### Pattern 1: Rebuild-Required vs Live-Editable Boundary

**What:** A strict two-tier system separates structural config (Nix, rebuild-required) from content (documents/skills/cron, live-editable via `mkOutOfStoreSymlink`).

**When to use:** Always. The boundary is the load-bearing architectural decision for this project.

**Trade-offs:** Discipline required — content that accidentally lands in `config.toml` instead of a symlinked file breaks the no-rebuild workflow.

**Implementation:**
```nix
# Rebuild-required: rendered into Nix store, copied to ~/.zeroclaw/config.toml
home.file.".zeroclaw/config.toml" = {
  source = pkgs.writeText "zeroclaw-config.toml" ''...'';
  force = true;
};

# Live-editable: symlink bypasses Nix store, edits take effect immediately
home.file.".zeroclaw/documents/IDENTITY.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/IDENTITY.md";
```

### Pattern 2: Git-First Self-Modification

**What:** Kiro makes all changes to its own config in `/etc/nixos/zeroclaw/` and commits to git. No ad-hoc runtime writes outside version control.

**When to use:** Always — for documents, skills, and cron. Runtime state (`~/.zeroclaw/state/`) is exempt (ephemeral by design).

**Trade-offs:** Adds git commit overhead to self-modification. Benefit: full audit trail, rollback capability, and single source of truth enforcement.

### Pattern 3: Service Lifecycle Coupling (PartOf)

**What:** The Kapso WhatsApp bridge is declared as `PartOf = zeroclaw-gateway.service`. When the gateway stops, the bridge stops. When the bridge crashes repeatedly, gateway lifecycle is unaffected.

**When to use:** Any auxiliary service that is meaningless without the primary service.

**Trade-offs:** Bridge cannot outlive the gateway (correct behavior). Restart limits (`StartLimitBurst`) protect against crash loops.

```nix
systemd.user.services.kapso-whatsapp-bridge.Unit.PartOf = [ "zeroclaw-gateway.service" ];
systemd.user.services.kapso-whatsapp-bridge.Unit.StartLimitIntervalSec = 60;
systemd.user.services.kapso-whatsapp-bridge.Unit.StartLimitBurst = 10;
```

### Pattern 4: Secrets via EnvironmentFile

**What:** Secrets never appear in Nix store (world-readable). They are rendered by sops-nix to `/run/secrets/rendered/zeroclaw.env` and injected via systemd `EnvironmentFile`.

**When to use:** All secrets — API keys, gateway tokens, Kapso credentials.

**Trade-offs:** Secrets are available only at runtime, not at `nixos-rebuild` eval time. Config.toml cannot reference secret values directly; they must be env var expansions read by the ZeroClaw runtime.

---

## Data Flow

### Config Source of Truth → Runtime

```
/etc/nixos/zeroclaw/module.nix
    │
    │ nixos-rebuild switch
    ▼
~/.zeroclaw/config.toml           (rendered Nix, structural config)
~/.zeroclaw/documents/ → symlink  (identity, live)
~/.zeroclaw/skills/    → symlink  (skills, live)
~/.zeroclaw/cron/      → symlink  (cron jobs, live)
    │
    │ zeroclaw daemon reads on startup
    ▼
zeroclaw-gateway.service
    │
    ├──► Agent core (LLM, tools, memory)
    ├──► Cron scheduler (reads cron/ directory)
    └──► WebSocket :42617 → kapso-whatsapp-bridge → WhatsApp
```

### Inbound Message Flow (WhatsApp)

```
WhatsApp owner message
    │
    ▼
Kapso bridge (kapso-whatsapp-bridge.service)
    │ WebSocket /ws/chat
    ▼
ZeroClaw gateway (:42617)
    │
    ▼
Channel handler → Agent turn → Tool dispatch → LLM (Z.AI)
    │                               │
    │                               ▼
    │                         Memory (SQLite)
    │                         Skills execution
    │                         Shell / browser / search
    ▼
Response → Kapso bridge → WhatsApp delivery (Tailscale mode)
```

### Self-Modification Flow (Kiro edits its own config)

```
Kiro decides to edit/create a document, skill, or cron job
    │
    │ file_write tool to /etc/nixos/zeroclaw/<path>
    ▼
File written to source of truth
    │
    │ shell tool: git add + gcommit
    ▼
Change committed to git
    │
    │ ZeroClaw picks up via symlink (documents/skills/cron) immediately
    │ OR next rebuild picks up (module.nix structural changes)
    ▼
Change active (no rebuild required for symlinked content)
```

---

## Build Order (Phase Dependencies)

The dependency graph below determines safe phase ordering:

```
1. module.nix (structural config)
        │
        │ must exist before anything else can run
        ▼
2. config.toml sections (model providers, autonomy, memory, observability)
        │
        │ gateway must be configured before channels work
        ▼
3. documents/ (identity wired, symlinks declared in module.nix)
        │
        │ identity needed before agent is useful
        ▼
4. cron/ (job definitions, symlinks declared)
        │
        │ scheduler needs config.toml cron section enabled
        ▼
5. skills/ (skill manifests, symlinks declared)
        │
        │ skills build on top of a working agent + autonomy config
        ▼
6. Advanced config (sub-agents, model routing, research phase, observability)
```

Implication for roadmap phases:
- **Phase 1** must produce a working `module.nix` with all symlinks declared, minimal config.toml, and services running.
- **Phase 2** fills in config.toml completeness (all relevant sections) and identity documents.
- **Phase 3** adds cron job definitions.
- **Phase 4** adds skills scaffolding and first skills.
- **Phase 5** is advanced tuning (sub-agents, model routes, observability).

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Z.AI (zai, zai-coding) | `[model_providers.zai]` with `wire_api = "chat_completions"` | NOT `openai-responses` — returns 404. Two endpoints: base + coding. |
| Kapso WhatsApp bridge | WebSocket `ws://127.0.0.1:42617/ws/chat`, secrets via sops | `PartOf` gateway. Delivery via Tailscale mode. |
| Brave Search | `[web_search] provider = "brave"`, `BRAVE_API_KEY` env var | Already in zeroclaw.env via sops |
| Chrome / Playwright | `[browser] native_chrome_path = "/run/current-system/sw/bin/kiro-browser"` | Dedicated Chrome profile script |

### Internal Module Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| NixOS build → home-manager | `home.file.*` declarations | `force = true` needed on config.toml (avoids HM collision) |
| home-manager → systemd | `systemd.user.services.*` | Gateway service runs as user `hybridz`, not root |
| sops-nix → zeroclaw daemon | `EnvironmentFile = /run/secrets/rendered/zeroclaw.env` | Rendered by `zeroclaw-secrets.nix` module |
| zeroclaw-gateway → kapso-bridge | WebSocket on localhost:42617 | Bridge uses `gateway.type = "zeroclaw"` |
| source tree → deployment | `mkOutOfStoreSymlink` for live-edit paths | Symlinks point to absolute `/etc/nixos/zeroclaw/` paths |

---

## Anti-Patterns

### Anti-Pattern 1: Editing `~/.zeroclaw/` Directly

**What people do:** Edit `~/.zeroclaw/config.toml` or files there directly for quick fixes.

**Why it's wrong:** The next `nixos-rebuild switch` overwrites config.toml (it has `force = true`). Symlinked paths (`documents/`, `skills/`, `cron/`) cannot be edited via their symlink targets anyway — the source of truth is `/etc/nixos/zeroclaw/`. Direct edits are lost and bypasses git history.

**Do this instead:** Edit `/etc/nixos/zeroclaw/` and commit. For structural config changes, rebuild. For symlinked content, changes are live immediately after editing and committing.

### Anti-Pattern 2: Putting Mutable Content in config.toml

**What people do:** Add identity text, skill descriptions, or job prompts directly into the `configToml` Nix string in `module.nix`.

**Why it's wrong:** Any change requires `sudo nixos-rebuild switch`. Kiro cannot self-modify this content. Git diffs become noisy Nix string changes.

**Do this instead:** Identity content goes in `documents/` (symlinked). Skill prompts go in `skills/<name>/SKILL.toml` (symlinked). Cron prompts go in `cron/<name>.toml` (symlinked). Only structural config (ports, provider URLs, autonomy levels, service wiring) belongs in `module.nix`.

### Anti-Pattern 3: Secrets in Nix Store

**What people do:** Hardcode API keys in `configToml` Nix string or pass them as Nix values.

**Why it's wrong:** The Nix store is world-readable (`/nix/store/...`). Any user on the system can read it.

**Do this instead:** All secrets go through sops-nix → `/run/secrets/rendered/zeroclaw.env` → `EnvironmentFile` in the systemd unit.

### Anti-Pattern 4: Using `openai-responses` Wire API for Z.AI

**What people do:** Configure `wire_api = "openai-responses"` for the Z.AI provider (it looks like it should work).

**Why it's wrong:** Z.AI returns 404 on the responses endpoint. Only `chat_completions` works.

**Do this instead:** `wire_api = "chat_completions"` for both `zai` and `zai-coding` providers.

---

## NixOS-Specific Patterns

### mkOutOfStoreSymlink for Live Edits

Standard `home.file.*.source` copies files into the Nix store (immutable). `mkOutOfStoreSymlink` creates a symlink from the deployment path to the source tree path. The target file remains mutable.

```nix
# This copies into Nix store — immutable, rebuild-required for changes
home.file.".zeroclaw/documents/IDENTITY.md".source = ./documents/IDENTITY.md;

# This creates a live symlink — edits in source tree take effect immediately
home.file.".zeroclaw/documents/IDENTITY.md".source =
  config.lib.file.mkOutOfStoreSymlink "/etc/nixos/zeroclaw/documents/IDENTITY.md";
```

Absolute paths required. Relative paths silently fail or resolve incorrectly.

### systemd EnvironmentFile for Secrets

```nix
Service = {
  ExecStart = "${zeroclawPkg}/bin/zeroclaw daemon";
  EnvironmentFile = [ "/run/secrets/rendered/zeroclaw.env" ];
};
```

The `zeroclaw-secrets.nix` module (in `modules/services/`) handles sops decryption and rendering to `/run/secrets/rendered/zeroclaw.env` at boot.

### Service Dependency Ordering

```nix
# Gateway waits for network but starts before bridge
Unit.After = [ "network-online.target" ];
Unit.Wants = [ "kapso-whatsapp-bridge.service" ];

# Bridge is bound to gateway lifecycle
systemd.user.services.kapso-whatsapp-bridge.Unit.PartOf = [ "zeroclaw-gateway.service" ];
```

---

## Scaling Considerations

This is a single-user personal agent. Scaling is not a concern. Relevant operational constraints instead:

| Concern | Current Approach |
|---------|-----------------|
| Cost control | `[cost]` section with daily/monthly limits; Brave search is pre-paid |
| Autonomy safety | `[autonomy] level = "supervised"` — medium-risk commands require approval |
| Security | OTP gating, estop capability, syscall anomaly detection available |
| Self-modification audit | Git-first workflow — all changes traceable |
| Recovery | `nixos-rebuild switch` restores structural config; git revert restores content |

---

## Sources

- `/etc/nixos/zeroclaw/module.nix` — current deployed module (HIGH confidence, live code)
- `/home/hybridz/Projects/zeroclaw/docs/config-reference.md` — upstream ZeroClaw docs, verified Feb 25, 2026 (HIGH confidence)
- `/etc/nixos/zeroclaw/reference/upstream-docs/commands-reference.md` — CLI surface, verified Feb 25, 2026 (HIGH confidence)
- `/etc/nixos/zeroclaw/reference/upstream-docs/operations-runbook.md` — ops patterns, verified Feb 18, 2026 (HIGH confidence)
- `/etc/nixos/zeroclaw/.planning/PROJECT.md` — project requirements and decisions (HIGH confidence)
- `/etc/nixos/openclaw/CLAUDE.md` — previous OpenClaw architecture (reference for migration context)

---

*Architecture research for: ZeroClaw agent infrastructure on NixOS*
*Researched: 2026-03-04*
