---
phase: 1
slug: config-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-04
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None (NixOS config project — no unit test framework) |
| **Config file** | none |
| **Quick run command** | `nix flake check` |
| **Full suite command** | `sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos && zeroclaw doctor` |
| **Estimated runtime** | ~60–120 seconds (rebuild) |

---

## Sampling Rate

- **After every task commit:** Run `nix flake check`
- **After every plan wave:** Run `nix build .#nixosConfigurations.nixos.config.system.build.toplevel`
- **Before `/gsd:verify-work`:** Full 6-gate suite must pass
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | CFG-01 | smoke | `zeroclaw status 2>&1 \| grep -E "Workspace only\|Allowed roots"` | ❌ Wave 0 | ⬜ pending |
| 1-01-02 | 01 | 1 | CFG-02 | smoke | `zeroclaw status 2>&1 \| grep -i sqlite` | ❌ Wave 0 | ⬜ pending |
| 1-01-03 | 01 | 1 | CFG-03 | smoke | `cat ~/.zeroclaw/config.toml \| grep runtime_trace_mode` | ❌ Wave 0 | ⬜ pending |
| 1-01-04 | 01 | 1 | CFG-04 | smoke | `cat ~/.zeroclaw/config.toml \| grep max_tool_iterations` | ❌ Wave 0 | ⬜ pending |
| 1-01-05 | 01 | 1 | CFG-05 | smoke | `nix flake check && nix build .#nixosConfigurations.nixos.config.system.build.toplevel` | ❌ Wave 0 | ⬜ pending |
| 1-01-06 | 01 | 1 | DIR-04 | smoke | `ls /etc/nixos/zeroclaw/reference/upstream-docs \| head -5` | ✅ exists | ⬜ pending |
| 1-01-07 | 01 | 1 | IPC-01 | smoke | `cat ~/.zeroclaw/config.toml \| grep "enabled = true"` | ❌ Wave 0 | ⬜ pending |
| 1-01-08 | 01 | 1 | IPC-02 | smoke | `ls ~/.zeroclaw/agents.db 2>/dev/null \|\| echo "created on first use"` | ❌ Wave 0 | ⬜ pending |
| 1-01-09 | 01 | 1 | MOD-02 | smoke | `readlink -f ~/.zeroclaw/workspace/SOUL.md` | ❌ Wave 0 | ⬜ pending |
| 1-01-10 | 01 | 1 | MOD-02 | smoke | `readlink -f ~/.zeroclaw/reference/upstream-docs \| grep zeroclaw/docs` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `/etc/nixos/zeroclaw/skills/` — create empty placeholder directory
- [ ] `/etc/nixos/zeroclaw/cron/` — create empty placeholder directory

*No test framework install needed — smoke tests use `nix` and `zeroclaw` CLI tools already on PATH.*

---

## Phase Gate Commands (post-rebuild)

```bash
# Gate 1: Syntax + build
nix flake check && nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Gate 2: Activate
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos

# Gate 3: Verify (acceptable: max 3 warnings — api_key env, no channels, no channel-components)
zeroclaw doctor

# Gate 4: Functional test (must return response, not 404 or auth error)
zeroclaw agent -m "hello"

# Gate 5: Autonomy test (must NOT produce "path not allowed" error)
zeroclaw agent -m "run: git status in /etc/nixos/zeroclaw"

# Gate 6: Symlink chain (must resolve to /home/hybridz/Projects/zeroclaw/docs)
readlink -f ~/.zeroclaw/reference/upstream-docs
```

**Note on "zero warnings" criterion:** 3 warnings are non-eliminatable with this architecture:
1. `api_key` uses environment variable (correct pattern — not a real warning)
2. No native ZeroClaw channels configured (Kapso bridge is an external WebSocket, not a native channel)
3. No channel-components defined (same reason as above)

These 3 are acceptable. Any additional warnings indicate a real config problem.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Kiro auto-approves git status via WhatsApp | CFG-01 | Requires live WhatsApp session | Send "git status" via WhatsApp; verify response not "approval required" |
| Live-edit: edit identity doc, verify immediate visibility | MOD-02 | Requires editing then reading without rebuild | Edit IDENTITY.md, check `cat ~/.zeroclaw/documents/IDENTITY.md` reflects change |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
