---
phase: quick-3
plan: 1
subsystem: module.nix / home-manager
tags: [symlinks, home-manager, activation, zeroclaw]
dependency_graph:
  requires: []
  provides: [MOD-02]
  affects: [zeroclaw-identity-docs, zeroclaw-workspace]
tech_stack:
  added: []
  patterns: [home.activation, lib.hm.dag.entryAfter, ln -sf direct symlink]
key_files:
  modified:
    - /etc/nixos/zeroclaw/module.nix
decisions:
  - "home.activation with ln -sf chosen over mkOutOfStoreSymlink to eliminate nix store intermediate hop"
metrics:
  duration: ~5min
  completed: 2026-03-05
---

# Quick Task 3: Fix Document Symlinks to Use home.activation Summary

**One-liner:** Replaced 8 `home.file` `mkOutOfStoreSymlink` entries with a single `home.activation.zeroclawDocuments` block using `ln -sf` for direct 1-hop symlinks, eliminating the nix store intermediate that blocked ZeroClaw's security policy.

## What Was Done

The 8 `home.file` entries using `config.lib.file.mkOutOfStoreSymlink` for identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) and workspace symlinks (SOUL.md, AGENTS.md) were replaced with a single `home.activation` block.

**Before:** Each symlink resolved through a 3-hop nix store chain:
`~/.zeroclaw/documents/SOUL.md` -> `/nix/store/.../hm-files/...` -> `/nix/store/.../hm_SOUL.md` -> `/etc/nixos/zeroclaw/documents/SOUL.md`

**After:** Each symlink resolves directly in 1 hop:
`~/.zeroclaw/documents/SOUL.md` -> `/etc/nixos/zeroclaw/documents/SOUL.md`

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace mkOutOfStoreSymlink entries with home.activation | 950305e | module.nix |
| 2 | Build, activate, and verify direct symlinks | (part of same commit) | - |

## Verification Results

All 8 symlinks verified as direct 1-hop after rebuild:

```
IDENTITY.md -> /etc/nixos/zeroclaw/documents/IDENTITY.md
SOUL.md     -> /etc/nixos/zeroclaw/documents/SOUL.md
AGENTS.md   -> /etc/nixos/zeroclaw/documents/AGENTS.md
TOOLS.md    -> /etc/nixos/zeroclaw/documents/TOOLS.md
USER.md     -> /etc/nixos/zeroclaw/documents/USER.md
LORE.md     -> /etc/nixos/zeroclaw/documents/LORE.md
~/.zeroclaw/workspace/SOUL.md   -> /etc/nixos/zeroclaw/documents/SOUL.md
~/.zeroclaw/workspace/AGENTS.md -> /etc/nixos/zeroclaw/documents/AGENTS.md
```

`nix flake check` passed. `nixos-rebuild switch` completed successfully.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- module.nix modified: FOUND
- home.activation.zeroclawDocuments present: FOUND
- No mkOutOfStoreSymlink for documents/workspace: CONFIRMED
- home.file.".zeroclaw/reference" (mkOutOfStoreSymlink for reference dir): PRESERVED
- Commit 950305e: FOUND
- All 8 symlinks resolve to /etc/nixos/zeroclaw/documents/ directly: CONFIRMED
