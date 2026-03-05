---
phase: quick
plan: 2
type: execute
wave: 1
depends_on: []
files_modified:
  - /etc/nixos/zeroclaw/module.nix
autonomous: true
requirements: []
must_haves:
  truths:
    - "Kiro can read files under ~/.zeroclaw/documents/ without security policy errors"
    - "All six identity documents (IDENTITY, SOUL, AGENTS, TOOLS, USER, LORE) are readable by Kiro"
  artifacts:
    - path: "/etc/nixos/zeroclaw/module.nix"
      provides: "Updated allowed_roots including ~/.zeroclaw/documents/"
      contains: "~/.zeroclaw/documents/"
  key_links:
    - from: "module.nix [autonomy].allowed_roots"
      to: "~/.zeroclaw/documents/"
      via: "TOML config rendered at build time"
      pattern: "allowed_roots.*zeroclaw/documents"
---

<objective>
Add `~/.zeroclaw/documents/` to Kiro's `allowed_roots` so Kiro can read its own identity documents.

Purpose: The documents are symlinked from `/etc/nixos/zeroclaw/documents/` to `~/.zeroclaw/documents/`. Kiro accesses them via the `~/.zeroclaw/documents/` path, which is not in `allowed_roots`, causing "security policy restriction" errors. Adding the path unblocks Kiro from reading IDENTITY.md, SOUL.md, AGENTS.md, TOOLS.md, USER.md, and LORE.md.

Output: Updated `module.nix` with `~/.zeroclaw/documents/` in `allowed_roots`, rebuilt and activated.
</objective>

<execution_context>
@/home/hybridz/.claude/get-shit-done/workflows/execute-plan.md
@/home/hybridz/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/etc/nixos/zeroclaw/module.nix
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add ~/.zeroclaw/documents/ to allowed_roots in module.nix</name>
  <files>/etc/nixos/zeroclaw/module.nix</files>
  <action>
    In `module.nix`, locate the `[autonomy]` section (around line 48). Find the `allowed_roots` line:

    ```toml
    allowed_roots = ["/etc/nixos/", "~/Projects/"]
    ```

    Change it to:

    ```toml
    allowed_roots = ["/etc/nixos/", "~/Projects/", "~/.zeroclaw/documents/"]
    ```

    This adds the path Kiro uses to access its identity documents. The symlinks at `~/.zeroclaw/documents/` point back to `/etc/nixos/zeroclaw/documents/`, but Kiro's file access check uses the symlink path, not the resolved path — so the symlink target path must be in `allowed_roots`.

    Do NOT add `~/.zeroclaw/` broadly — that would expose workspace internals. Scope the addition to `~/.zeroclaw/documents/` only.
  </action>
  <verify>
    <automated>grep 'allowed_roots' /etc/nixos/zeroclaw/module.nix</automated>
  </verify>
  <done>The `allowed_roots` line includes `"~/.zeroclaw/documents/"` as a third entry.</done>
</task>

<task type="auto">
  <name>Task 2: Validate and rebuild NixOS to activate the change</name>
  <files>/etc/nixos/zeroclaw/module.nix</files>
  <action>
    Run the three-step rebuild sequence to activate the updated config:

    Step 1 — Syntax check (fast):
    ```bash
    cd /etc/nixos && nix flake check
    ```

    Step 2 — Full build test (confirms the full config compiles):
    ```bash
    nix build .#nixosConfigurations.nixos.config.system.build.toplevel
    ```

    Step 3 — Rebuild and activate:
    ```bash
    sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos
    ```

    After activation, commit the change:
    ```bash
    cd /etc/nixos/zeroclaw && git add module.nix && git commit -m "fix(module): add ~/.zeroclaw/documents/ to allowed_roots so Kiro can read identity docs"
    ```
  </action>
  <verify>
    <automated>grep -A5 'allowed_roots' ~/.zeroclaw/config.toml</automated>
  </verify>
  <done>`~/.zeroclaw/config.toml` (the rendered runtime config) contains `~/.zeroclaw/documents/` in the `allowed_roots` array. Change committed to git.</done>
</task>

</tasks>

<verification>
After rebuild, verify Kiro can actually read the documents by asking it: "Read your IDENTITY.md and summarize your purpose." Kiro should respond with content from the file rather than a security policy error.
</verification>

<success_criteria>
- `allowed_roots` in `module.nix` includes `"~/.zeroclaw/documents/"`
- `~/.zeroclaw/config.toml` reflects the change (rebuilt and activated)
- Kiro can read identity documents without "security policy restriction" errors
- Change committed to git
</success_criteria>

<output>
After completion, create `.planning/quick/2-fix-kiro-allowed-roots-so-it-can-read-do/2-SUMMARY.md`
</output>
