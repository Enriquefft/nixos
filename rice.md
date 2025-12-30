# Cyber Tardigrade Rice Specification

> NixOS + Hyprland rice with "Research Terminal" aesthetic. 4K monitor scaled to 2K (1.5x).

## Palette

```
bg_base       #0d0d1a    Main background
bg_surface    #1a1432    Panels, bars
bg_elevated   #2a2045    Popups, menus
fg_dim        #6b6b8a    Comments, inactive
fg_normal     #a8a8c0    Body text
fg_bright     #d4d4e8    Headings, focus
accent_cyan   #5a8fba    Links, info
accent_purple #7a4a8a    Selections
accent_magenta #b55a9a   Keywords
accent_orange #e86a30    Active borders, focus (PRIMARY ACCENT)
accent_gold   #f0a050    Warnings, special
success       #5aaa7a    Git add, success
error         #d55a5a    Git del, errors
border        #3a3055    Inactive borders
```

## Stack

| Component | Package | Config Location |
|-----------|---------|-----------------|
| Compositor | hyprland | ~/.config/hypr/hyprland.conf |
| Bar | waybar | ~/.config/waybar/{config.jsonc,style.css} |
| Launcher | wofi | ~/.config/wofi/{config,style.css} |
| Terminal | kitty | ~/.config/kitty/kitty.conf |
| Shell | zsh + powerlevel10k | ~/.zshrc, ~/.p10k.zsh |
| Editor | neovim (nixvim) | NixOS module |
| Notifications | swaync | ~/.config/swaync/{config.json,style.css} |
| Wallpaper | hyprpaper | ~/.config/hypr/hyprpaper.conf |
| Lock | hyprlock | ~/.config/hypr/hyprlock.conf |
| Screenshots | hyprshot | - |
| Night mode | hyprsunset | - |
| Music | rff | GTK themed |

## Packages (NixOS)

```nix
# Core
hyprland hyprlock hypridle hyprpaper hyprshot hyprsunset hyprpicker
xdg-desktop-portal-hyprland

# Desktop
waybar wofi wlogout swaync libnotify

# Terminal
kitty zsh zsh-powerlevel10k zsh-autosuggestions zsh-syntax-highlighting

# Utils
wl-clipboard cliphist grim slurp brightnessctl
pipewire wireplumber pavucontrol playerctl blueman
thunar yazi btop fastfetch

# CLI
eza bat ripgrep fd fzf zoxide lazygit

# Theming
nwg-look gradience qt5ct qt6ct
(nerdfonts.override { fonts = [ "JetBrainsMono" ]; })

# Media
rff cava
```

## Hyprland Config

```conf
# Monitor: 4K → 2K
monitor = , preferred, auto, 1.5

# Appearance
general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2
    col.active_border = rgb(e86a30)      # Orange glow
    col.inactive_border = rgb(3a3055)
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 6
        passes = 2
    }
    shadow {
        enabled = true
        color = rgba(e86a3033)
    }
}

animations {
    bezier = easeOut, 0.25, 1, 0.5, 1
    animation = windows, 1, 3, easeOut
    animation = workspaces, 1, 4, easeOut, slide
    animation = fade, 1, 3, default
}

# Keybinds
$mod = SUPER
bind = $mod, Return, exec, kitty
bind = $mod, Q, killactive
bind = $mod, D, exec, wofi --show drun
bind = $mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy
bind = $mod, L, exec, hyprlock
bind = $mod, N, exec, pkill hyprsunset || hyprsunset -t 4500
bind = $mod, E, exec, kitty -e yazi
bind = $mod, X, exec, wlogout
bind = $mod, B, exec, pkill waybar || waybar
bind = , Print, exec, hyprshot -m region
bind = $mod, 1-9, workspace, 1-9
bind = $mod SHIFT, 1-9, movetoworkspace, 1-9
bind = $mod, h/j/k/l, movefocus, l/d/u/r
bind = $mod, F, fullscreen
bind = $mod, Space, togglefloating

# Autostart
exec-once = waybar
exec-once = hyprpaper
exec-once = swaync
exec-once = wl-paste --watch cliphist store
```

## Waybar

### config.jsonc
```jsonc
{
    "layer": "top",
    "position": "top",
    "modules-left": ["custom/logo", "hyprland/workspaces", "hyprland/window"],
    "modules-center": ["cpu", "memory", "network"],
    "modules-right": ["mpris", "clock", "tray"],

    "custom/logo": { "format": "󰣇", "on-click": "wofi --show drun" },
    "hyprland/workspaces": { "format": "{id}" },
    "cpu": { "format": " {usage}%", "on-click": "kitty -e btop" },
    "memory": { "format": " {percentage}%" },
    "network": { "format": "󰈀 {bandwidthDownBits} ↓ {bandwidthUpBits} ↑" },
    "mpris": { "format": "♪ {title} - {artist}" },
    "clock": { "format": "󰃰 {:%b %d  %H:%M}" }
}
```

### style.css
```css
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
}
window#waybar { background: #1a1432; color: #a8a8c0; }
#workspaces button { color: #7a4a8a; padding: 0 8px; }
#workspaces button.active { background: #e86a30; color: #0d0d1a; border-radius: 4px; }
#cpu, #memory, #network { padding: 0 12px; }
#mpris { color: #5a8fba; }
#clock { color: #f0a050; }
#tray { padding: 0 8px; }
```

## Kitty

```conf
font_family JetBrainsMono Nerd Font
font_size 12
background_opacity 0.92
background #0d0d1a
foreground #a8a8c0
cursor #e86a30
selection_background #2a2045
color0 #0d0d1a
color1 #d55a5a
color2 #5aaa7a
color3 #f0a050
color4 #5a8fba
color5 #b55a9a
color6 #5a8fba
color7 #a8a8c0
color8 #6b6b8a
color9 #d55a5a
color10 #5aaa7a
color11 #f0a050
color12 #5a8fba
color13 #b55a9a
color14 #5a8fba
color15 #d4d4e8
```

## Powerlevel10k

Key customizations for `~/.p10k.zsh`:
```zsh
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND='#e86a30'
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND='#d55a5a'
typeset -g POWERLEVEL9K_DIR_FOREGROUND='#5a8fba'
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#5aaa7a'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#f0a050'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#e86a30'
```

## NixVim Base16

```nix
programs.nixvim.colorschemes.base16 = {
  enable = true;
  customColorScheme = {
    base00 = "0d0d1a"; base01 = "1a1432"; base02 = "2a2045"; base03 = "6b6b8a";
    base04 = "a8a8c0"; base05 = "d4d4e8"; base06 = "d4d4e8"; base07 = "d4d4e8";
    base08 = "d55a5a"; base09 = "e86a30"; base0A = "f0a050"; base0B = "5aaa7a";
    base0C = "5a8fba"; base0D = "5a8fba"; base0E = "b55a9a"; base0F = "7a4a8a";
  };
};
```

## Wofi

### style.css
```css
window { background: #1a1432f2; border: 2px solid #3a3055; border-radius: 8px; }
#input { background: #0d0d1a; color: #d4d4e8; border: none; padding: 12px; }
#entry { padding: 8px; }
#entry:selected { background: #e86a30; color: #0d0d1a; }
```

## Swaync

Urgency colors:
- Low: `border-left: 3px solid #5a8fba`
- Normal: `border-left: 3px solid #7a4a8a`
- Critical: `border-left: 3px solid #e86a30; box-shadow: 0 0 10px #e86a3066`

## Directory Structure

```
~/.config/
├── hypr/{hyprland.conf,hyprpaper.conf,hyprlock.conf}
├── waybar/{config.jsonc,style.css}
├── kitty/kitty.conf
├── wofi/{config,style.css}
├── swaync/{config.json,style.css}
└── fastfetch/config.jsonc

~/nixos/modules/
├── colors.nix          # Palette definitions
├── hyprland.nix
├── waybar.nix
├── kitty.nix
├── zsh.nix
├── nixvim.nix
└── swaync.nix
```

## Implementation Order

1. **Base**: Hyprland + monitor scaling + hyprpaper
2. **Terminal**: Kitty + Zsh + P10k + CLI tools
3. **Bar**: Waybar config + CSS
4. **Launcher**: Wofi + clipboard/power scripts
5. **Polish**: Animations, blur, keybinds, hyprlock
6. **Editor**: NixVim + colorscheme
7. **Notifications**: Swaync + control center
8. **Final**: GTK/QT theming, Rff, fastfetch
