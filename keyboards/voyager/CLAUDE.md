# CLAUDE.md

## What This Is

**Entry point for all keyboard customization.** Firmware layout lives here; OS-level binds live in `/etc/nixos`. Both must stay in sync — start here, then propagate changes outward. ZSA Voyager in **local mode** — `layout.toml` is the canonical firmware layout, not Oryx cloud. Managed via the `oryx-bench` CLI. The `oryx-bench` skill (`.claude/skills/oryx-bench/SKILL.md`) provides detailed operational guidance — read it for Path A vs Path B classification, safety rules, and anti-pattern handling.

## Commands

```bash
oryx-bench status              # ALWAYS run first — shows mode, sync state, lint summary
oryx-bench show [LAYER]        # ASCII grid of layer(s)
oryx-bench explain POSITION    # Cross-layer view of one key position
oryx-bench find QUERY          # Search keycodes across all layers
oryx-bench lint [--strict]     # Static analysis
oryx-bench build               # Compile firmware (Docker backend)
oryx-bench diff [REF]          # Semantic diff vs git ref — show before flashing
oryx-bench flash [--yes]       # Flash to keyboard — REQUIRES explicit user approval
```

## Project Structure

| File | Role |
|------|------|
| `kb.toml` | Project config — geometry (voyager), build backend (docker), sync settings |
| `layout.toml` | **Source of truth** for visual layout. 4 layers: Main (Colemak-DH), Layer_1 (symbols), Layer_2 (nav/numpad/F-keys), Gaming (QWERTY) |
| `overlay/features.toml` | Declarative QMK features — tapping term, achordion, key overrides, combos, macros |
| `overlay/*.zig` | Procedural code — tap dances, state machines, RGB (Tier 2) |
| `overlay/*.c` | Vendored upstream C libs — paste-only, never edit |

## Local Mode Rules

- Visual layout changes go directly in `layout.toml` (no Oryx involvement)
- `pulled/` directory does not exist — no sync, no auto-pull
- Behavior changes (achordion, overrides, macros) go in `overlay/features.toml` or `overlay/*.zig`
- Position names in `layout.toml` are canonical (e.g. `L_pinky_home`, `R_thumb_outer`) — verify with `oryx-bench explain` before referencing

## Current Layout

- **Main**: Colemak-DH. Home-row shift (L_outer_home = LSFT). LALT on Z, RALT on /. Space left thumb, Enter/Backspace right thumb (layer-tap to Layer_1/Layer_2).
- **Layer_1**: Symbols and brackets. Media controls on left number row.
- **Layer_2**: Arrow keys + navigation left, numpad right, F-keys on number row. Double-tap R_outer_bottom → Gaming.
- **Gaming**: Full QWERTY, no mod-taps. Double-tap R_outer_bottom → Main.

## Related NixOS Files

Firmware layout is half the story — OS-level config completes the keyboard experience. All paths relative to `/etc/nixos`.

**Sync-critical** — check on every layout/modifier/layer change:

| File | When it matters |
|------|-----------------|
| `home-manager/desktop/hyprland/keybinds.nix` | Moving/changing modifiers, layer-taps, or any key that Hyprland binds reference (Super, Alt, media keys). **Bidirectional** — changes flow both ways |
| `modules/services/input.nix` | keyd remapping — if a key is remapped at OS level, firmware change may conflict or become redundant |

**Context-dependent** — check when relevant:

| File | When it matters |
|------|-----------------|
| `home-manager/desktop/hyprland/input.nix` | Changing repeat rate, adding keyboards, touchpad/mouse tuning |
| `modules/hardware/keyboard.nix` | oryx-bench NixOS module config, udev rules, flash script toggles |
| `modules/hardware/peripherals.nix` | Flashing problems — ZSA udev rules live here |
| `scripts.nix` | Custom scripts bound to keys — create script here, bind in keybinds.nix or firmware |
| `applications.nix` | Keymapp package install |
| `flake.nix` | oryx-bench flake input version |

## Build

Firmware compiles via Docker (`[build] backend = "docker"` in `kb.toml`). Always lint before building. Always show `diff` and get user approval before flashing.
