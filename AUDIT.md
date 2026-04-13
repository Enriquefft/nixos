# NixOS System Audit — 2026-03-15

Non-zeroclaw findings from a full system audit. Fix at your own pace.

## Must Fix (broken)

1. **`kiro-browser`** references `/usr/bin/google-chrome-stable` — does NOT exist on NixOS. Use `${pkgs.google-chrome}/bin/google-chrome-stable` — `scripts.nix:874`
2. **`project-init`** references `/etc/nixos/templates/` — directory does not exist — `scripts.nix:1233`
3. **Wallpaper typo** `walppaper.png` (missing 'l') in `hyprlock.nix:18`, `wallpaper.nix:12,15`
4. **Conflicting colorschemes** — `gruvbox.enable = true` in `plugins/default.nix:17` fights `base16-default-dark` in `nixvim.nix`

## Should Fix (security, correctness, waste)

5. **Duplicate sudo + doas NOPASSWD rules** — identical 4 commands whitelisted in both — `security.nix`
6. **Remove `chromedriver` + `playwright`** from `applications.nix:138,91` — unused since browser backend change
7. **nixvim doesn't follow nixpkgs** — has own nixpkgs from Feb 6 (system is Mar 6). Uncomment `inputs.nixpkgs.follows` in `flake.nix:17`
8. **Duplicate home-manager import** — imported in both `flake.nix:84` and `configuration.nix:59`. Remove from configuration.nix
9. **Dead `flake-overlays` plumbing** — empty since xilinx removed. Remove curried arg from `configuration.nix:2` and `nixpkgs.overlays`
10. **PostgreSQL configured but disabled** — full ensureUsers/ensureDatabases but `enable = false` — `databases.nix`
11. **Broken zsh alias** to `./hyprland.nix` — actual file is `desktop/hyprland/default.nix` — `zsh.nix:82`
12. **`gcommit --ai` uses `claude-3-haiku-20240307`** — old model ID — `scripts.nix:117`

## Cleanup (dead code)

13. Extract `zc-watch` (330-line Python TUI) out of `scripts.nix:881-1212` into a standalone file
14. Remove entirely-commented `plugins/efm.nix`
15. Remove disabled `plugins/obsidian.nix`
16. Remove commented `open_grep` block — `scripts.nix:23-56`
17. Remove boilerplate comments in `home.nix:73-83, 170-197`
18. Fix stale battery comment ("85%" should say "60%") — `battery.nix`
19. `openclaw/` legacy directory — remove when migration complete
20. `factorio-gog.nix` hardcodes `/home/hybridz/Games/...` instead of using constants
21. Battery temp threshold `450` hardcoded in `battery.nix:171` — move to constants
22. Commented-out Colemak-DH remappings in `keymappings.nix:35-44`
23. Empty `extraPlugins = []` in `extra.nix:17`
24. TODO comments not addressed: `zsh.nix:84` ("move to dev shells"), `lsp.nix:93` ("disable for .env files")
