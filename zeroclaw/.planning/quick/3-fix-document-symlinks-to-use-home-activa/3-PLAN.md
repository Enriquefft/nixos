---
phase: quick-3
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - /etc/nixos/zeroclaw/module.nix
autonomous: true
requirements: [MOD-02]

must_haves:
  truths:
    - "~/.zeroclaw/documents/SOUL.md resolves to /etc/nixos/zeroclaw/documents/SOUL.md in a single hop"
    - "ZeroClaw can read identity documents without hitting a nix store intermediate path"
    - "All 6 identity documents and 2 workspace symlinks are created by home.activation"
  artifacts:
    - path: "/etc/nixos/zeroclaw/module.nix"
      provides: "home.activation block replacing home.file mkOutOfStoreSymlink entries"
      contains: "zeroclawDocuments"
  key_links:
    - from: "~/.zeroclaw/documents/SOUL.md"
      to: "/etc/nixos/zeroclaw/documents/SOUL.md"
      via: "direct ln -sf (1 hop, no nix store)"
      pattern: "ln -sf.*zeroclaw/documents"
---

<objective>
Replace the 8 `home.file` entries that use `mkOutOfStoreSymlink` for identity documents with a single `home.activation` block that creates direct 1-hop symlinks via `ln -sf`.

Purpose: ZeroClaw's security policy blocks access when a symlink chain passes through an intermediate nix store path. The current `mkOutOfStoreSymlink` approach creates a 3-hop chain (`~/.zeroclaw/documents/SOUL.md` → `/nix/store/.../hm-files/...` → `/nix/store/.../hm_SOUL.md` → `/etc/nixos/zeroclaw/documents/SOUL.md`). The `home.activation` approach creates a direct link with no nix store intermediate.

Output: Updated `module.nix` with `home.activation.zeroclawDocuments` block; NixOS rebuilt and activated.
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
  <name>Task 1: Replace mkOutOfStoreSymlink entries with home.activation in module.nix</name>
  <files>/etc/nixos/zeroclaw/module.nix</files>
  <action>
Edit `/etc/nixos/zeroclaw/module.nix`. Remove lines 101-118 (the 8 `home.file` entries using `mkOutOfStoreSymlink` for documents/ and workspace/ symlinks). Replace them with a single `home.activation` block:

```nix
  # Identity documents — direct symlinks via activation (avoids nix store hop blocking zeroclaw)
  home.activation.zeroclawDocuments = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.zeroclaw/documents"
    for doc in IDENTITY SOUL AGENTS TOOLS USER LORE; do
      ln -sf "/etc/nixos/zeroclaw/documents/$doc.md" "$HOME/.zeroclaw/documents/$doc.md"
    done
    ln -sf "/etc/nixos/zeroclaw/documents/SOUL.md" "$HOME/.zeroclaw/workspace/SOUL.md"
    ln -sf "/etc/nixos/zeroclaw/documents/AGENTS.md" "$HOME/.zeroclaw/workspace/AGENTS.md"
  '';
```

The `home.file.".zeroclaw/reference"` entry on line 121-122 (using `mkOutOfStoreSymlink` for the reference directory) is NOT affected — leave it unchanged. Only the 8 document entries are replaced.

Keep all other content in the file intact.
  </action>
  <verify>
    <automated>cd /etc/nixos && nix flake check 2>&1 | tail -5</automated>
  </verify>
  <done>nix flake check passes with no errors; module.nix contains `home.activation.zeroclawDocuments` and no `mkOutOfStoreSymlink` calls for the documents/ or workspace/ files</done>
</task>

<task type="auto">
  <name>Task 2: Build, activate, and verify direct symlinks</name>
  <files></files>
  <action>
Run the full NixOS rebuild sequence:

```bash
# Step 1: Full build test
nix build /etc/nixos#nixosConfigurations.nixos.config.system.build.toplevel

# Step 2: Activate
sudo nixos-rebuild switch --option eval-cache false --flake /etc/nixos#nixos
```

After activation, verify the symlinks are 1-hop direct links (not nix store chains):

```bash
# Should show: ~/.zeroclaw/documents/SOUL.md -> /etc/nixos/zeroclaw/documents/SOUL.md
ls -la ~/.zeroclaw/documents/SOUL.md

# Should resolve directly to /etc/nixos/zeroclaw/documents/SOUL.md (no nix store in path)
readlink -f ~/.zeroclaw/documents/SOUL.md

# Verify all 6 documents are direct symlinks
for doc in IDENTITY SOUL AGENTS TOOLS USER LORE; do
  target=$(readlink ~/.zeroclaw/documents/$doc.md)
  echo "$doc.md -> $target"
done

# Verify workspace symlinks
readlink ~/.zeroclaw/workspace/SOUL.md
readlink ~/.zeroclaw/workspace/AGENTS.md
```

Commit the change:
```bash
cd /etc/nixos/zeroclaw && git add module.nix && git commit -m "fix(module): replace mkOutOfStoreSymlink with home.activation for direct document symlinks"
```
  </action>
  <verify>
    <automated>readlink /home/hybridz/.zeroclaw/documents/SOUL.md</automated>
  </verify>
  <done>`readlink` returns `/etc/nixos/zeroclaw/documents/SOUL.md` directly (no nix store path); `readlink -f` confirms the same final target; all 6 documents and 2 workspace symlinks resolve cleanly</done>
</task>

</tasks>

<verification>
After both tasks complete:
- `readlink ~/.zeroclaw/documents/SOUL.md` returns `/etc/nixos/zeroclaw/documents/SOUL.md` (1 hop)
- No intermediate `/nix/store/` path appears in any symlink target
- `zeroclaw doctor` (if available) shows no document access warnings
- All 8 symlinks (6 documents + 2 workspace) exist and point directly to source
</verification>

<success_criteria>
Direct 1-hop symlinks replace the 3-hop nix store chains. ZeroClaw security policy no longer blocks identity document access. NixOS rebuild succeeded and system is running the updated config.
</success_criteria>

<output>
After completion, create `/etc/nixos/zeroclaw/.planning/quick/3-fix-document-symlinks-to-use-home-activa/3-SUMMARY.md` with what was done, files changed, and verification results.
</output>
