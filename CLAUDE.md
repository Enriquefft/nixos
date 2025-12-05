# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Test configuration (builds and activates without adding to boot menu)
sudo nixos-rebuild test --flake .#nixos

# Quick commit and push (custom script)
gpush "commit message"  # or just `gpush` for default "chore: regular commit"
```

**Important:** Never run `nixos-rebuild switch` or `nix flake update` - only use `test`.

## Architecture

This is a NixOS flake-based configuration for a single machine (`nixos`) running NixOS 25.11.

### Flake Structure
- **flake.nix**: Entry point defining inputs (nixpkgs, home-manager, nixvim, nix-index-database)
- **configuration.nix**: Main system configuration (accepts flake-overlays as argument)
- **home-manager/home.nix**: User configuration for `hybridz` user

### Key Modules
| File | Purpose |
|------|---------|
| `applications.nix` | System-wide packages |
| `nix.nix` | Nix daemon settings (flakes enabled, gc weekly) |
| `scripts.nix` | Custom shell scripts (`mant`, `last_logs`, `gpush`) |
| `hardware-configuration.nix` | Auto-generated hardware config |

### Home Manager Structure (`home-manager/`)
- `hyprland.nix` - Hyprland window manager config
- `programs/nixvim.nix` - Neovim configuration via nixvim
- `programs/nixvim/plugins/*.nix` - Individual nixvim plugin configs (LSP, treesitter, completion, etc.)
- `programs/waybar.nix`, `wofi.nix`, `kitty.nix`, `zsh.nix` - Desktop environment programs

### System Details
- Desktop: Hyprland (Wayland) with UWSM
- Shell: zsh (configured via home-manager)
- Editor: nixvim (Neovim)
- Terminal: kitty
- Intel GPU only (NVIDIA blacklisted for power saving)
- Services: PostgreSQL, MariaDB, Docker, Flatpak
