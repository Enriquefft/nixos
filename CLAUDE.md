# CLAUDE.md

This file provides guidance to coding agents (Claude Code, Copilot, ZeroClaw) working on this NixOS configuration.

## Build Commands

```bash
# Quick syntax validation
nix flake check

# Full build test (doesn't activate)
nix build .#nixosConfigurations.nixos.config.system.build.toplevel

# Rebuild and activate (use this after changes are working)
sudo nixos-rebuild switch --impure --option eval-cache false --flake /etc/nixos#nixos

# Commit and push
gpush "commit message"  # or just `gpush` for default "chore: regular commit"
```

**Important:** Never run `nix flake update`. Use `direnv reload` after editing `flake.nix`.

## Architecture

NixOS flake-based configuration for a single machine (`nixos`) running NixOS 25.11.

### Flake Structure
- **flake.nix** — inputs: nixpkgs, home-manager, nixvim, nix-index-database
- **configuration.nix** — main system config (imports modules/, accepts flake-overlays)
- **home-manager/home.nix** — user config for `hybridz`

### Root Files
| File | Purpose |
|------|---------|
| `applications.nix` | System-wide packages |
| `scripts.nix` | Custom shell scripts (see full list below) |
| `security.nix` | Sudo whitelist (NOPASSWD rules) |
| `virtualisation.nix` | Docker configuration |
| `hardware-configuration.nix` | Auto-generated hardware config |
| `zeroclaw/` | ZeroClaw agent config — skills, cron jobs, programs, documents (see `zeroclaw/CLAUDE.md`) |
| `openclaw/` | Legacy OpenClaw config (no longer imported, kept for reference/migration) |
| `shared/colors.nix` | Shared color palette |
| `shared/constants.nix` | GPU PCI addresses, hardware constants |
| `TROUBLESHOOTING.md` | Documented errors and solutions, keep up to date |

### Modules (`modules/`)
| Directory | Contents |
|-----------|----------|
| `hardware/` | `audio`, `bluetooth`, `graphics`, `nvidia-disable`, `peripherals` |
| `power/` | `battery`, `thermal` |
| `programs/` | `development`, `factorio-gog`, `firefox`, `hyprland`, `obs`, `steam`, `zsh` |
| `services/` | `databases`, `desktop`, `display`, `input`, `ollama`, `zeroclaw-secrets`, `tailscale` |
| `system/` | `boot`, `locale`, `networking`, `nix`, `users` |

### Home Manager (`home-manager/`)
- `home.nix` — main user config, imports programs (zeroclaw installed as package)
- `cursor.nix` — cursor theme
- `programs/kitty.nix`, `waybar.nix`, `wofi.nix`, `zsh.nix` — shell and desktop programs
- `programs/hyprland.nix`, `hypridle.nix`, `hyprlock.nix`, `swayosd.nix`, `wallpaper.nix` — WM and desktop
- `programs/nixvim.nix` + `nixvim/plugins/` — Neovim via nixvim (12 plugin configs: lsp, treesitter, avante, barbar, comment, efm, lualine, none-ls, obsidian, otter, startify)

### Scripts (`scripts.nix`)

All defined in `scripts.nix`, available on PATH:

| Script | Purpose |
|--------|---------|
| **System** | |
| `mant` | `journalctl -b -p 3` (current boot errors) |
| `last_logs` | `journalctl --boot=-1` (previous boot) |
| `gpu-toggle` | NVIDIA GPU on/off/status + Ollama start/stop (requires sudo) |
| `camon` / `camoff` | Camera module toggle (requires sudo) |
| `airplane` | Disable wifi, bluetooth, wwan |
| `con` | `nmcli connection up` shortcut |
| **Dev** | |
| `gpush` | git commit + pull --rebase + push (supports `--ai` for AI commit messages) |
| `gcommit` | git commit (supports `--ai` for AI-generated conventional commits) |
| `issue` | AI-powered `gh issue create` (researches codebase first if needed) |
| `project-init` | fzf template selector for new project flakes |
| `docker-rm` | Remove all docker images |
| **Desktop** | |
| `audio-switcher` | Wofi-based audio device picker |
| `kiro-browser` | Dedicated Chrome profile for ZeroClaw agent |
| `md2pdf` | Markdown to PDF via pandoc (xelatex/typst engines) |
| **ZeroClaw** | |
| `cron-sync` | Sync YAML job definitions to ZeroClaw cron DB |

### System Details
- Desktop: Hyprland (Wayland) with UWSM
- Shell: zsh (configured via home-manager)
- Editor: nixvim (Neovim)
- Terminal: kitty
- Intel GPU only (NVIDIA blacklisted for power saving, toggle-able via `gpu-toggle`)
- Services: PostgreSQL, MariaDB, Docker, Flatpak, Ollama, Tailscale
