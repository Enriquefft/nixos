# Hyprland Appearance Configuration
# Colors, borders, decorations, and animations
{ ... }:

let
  colors = (import ../../../shared/colors.nix).cyberTardigrade;
in {
  wayland.windowManager.hyprland.settings = {
    # General appearance
    general = {
      gaps_in = 4;
      gaps_out = 8;
      border_size = 2;
      "col.active_border" = "rgb(${colors.accent_orange})";
      "col.inactive_border" = "rgb(${colors.border})";
    };

    # Decorations (AC-only — effects enabled)
    decoration = {
      rounding = 8;
      blur = {
        enabled = true;
        size = 6;
        passes = 2;
      };
      shadow = {
        enabled = true;
        color = "rgba(${colors.accent_orange}33)";
      };
    };

    # Animations
    animations = {
      enabled = true;
      bezier = "easeOut, 0.25, 1, 0.5, 1";
      animation = [
        "windows, 1, 3, easeOut"
        "workspaces, 1, 4, easeOut, slide"
        "fade, 1, 3, default"
      ];
    };
  };
}
