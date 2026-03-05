---
phase: quick
plan: 2
subsystem: module.nix
tags: [allowed_roots, autonomy, identity-docs, nixos-rebuild]
dependency_graph:
  requires: []
  provides: [kiro-can-read-identity-docs]
  affects: [zeroclaw-gateway]
tech_stack:
  added: []
  patterns: [allowed_roots-scoping]
key_files:
  created: []
  modified:
    - /etc/nixos/zeroclaw/module.nix
decisions:
  - "Add only ~/.zeroclaw/documents/ — not ~/.zeroclaw/ broadly — to limit exposure to workspace internals"
  - "Remove invalid mode = 600 from home.file (not a valid home-manager option, blocked build)"
metrics:
  duration: 10min
  completed: "2026-03-04"
---

# Quick Task 2: Fix Kiro allowed_roots so it can read documents — Summary

**One-liner:** Added `~/.zeroclaw/documents/` to `allowed_roots` in `module.nix` so Kiro can read all six identity documents without security policy errors.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add ~/.zeroclaw/documents/ to allowed_roots | 66f5540 | module.nix |
| 2 | Validate and rebuild NixOS to activate the change | 66f5540 | (rebuild only) |

## What Was Done

Updated `module.nix` to add `~/.zeroclaw/documents/` as a third entry in `allowed_roots` under the `[autonomy]` section. Before:

```toml
allowed_roots = ["/etc/nixos/", "~/Projects/"]
```

After:

```toml
allowed_roots = ["/etc/nixos/", "~/Projects/", "~/.zeroclaw/documents/"]
```

The documents are symlinked from `/etc/nixos/zeroclaw/documents/` to `~/.zeroclaw/documents/`. Kiro's file access check uses the symlink path (not the resolved path), so the symlink directory must appear in `allowed_roots`. This change unblocks Kiro from reading IDENTITY.md, SOUL.md, AGENTS.md, TOOLS.md, USER.md, and LORE.md.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed invalid `mode = "600"` from home.file**

- **Found during:** Task 2 (nix flake check)
- **Issue:** `home.file.".zeroclaw/config.toml".mode` is not a valid home-manager option in the current version (NixOS 25.11). This was added by a previous commit (f2e713a) to suppress a world-readable warning. The option does not exist in this home-manager version and caused `nix flake check` to fail entirely, blocking the rebuild.
- **Fix:** Removed `mode = "600";` from the `home.file.".zeroclaw/config.toml"` block.
- **Files modified:** `/etc/nixos/zeroclaw/module.nix`
- **Commit:** 66f5540

## Verification

The rendered runtime config at `~/.zeroclaw/config.toml` was confirmed to contain `~/.zeroclaw/documents/` in `allowed_roots` after the rebuild:

```
allowed_roots = ["/etc/nixos/", "~/Projects/", "~/.zeroclaw/documents/"]
```

## Self-Check: PASSED

- `/etc/nixos/zeroclaw/module.nix` — modified (grep confirms `~/.zeroclaw/documents/` present)
- `~/.zeroclaw/config.toml` — rendered config confirmed (grep shows updated allowed_roots)
- Commit 66f5540 — confirmed in git log
