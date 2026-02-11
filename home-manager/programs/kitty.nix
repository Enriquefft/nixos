{
  config,
  pkgs,
  lib,
  ...
}:

let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in
{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    settings = {
      enable_audio_bell = false;

      # Opacity
      background_opacity = "0.92";

      # Colors - Cyber Tardigrade palette
      background = "#${colors.bg_base}";
      foreground = "#${colors.fg_normal}";
      cursor = "#${colors.accent_orange}";
      selection_background = "#${colors.bg_elevated}";

      # Black
      color0 = "#${colors.bg_base}";
      color8 = "#${colors.fg_dim}";

      # Red
      color1 = "#${colors.error}";
      color9 = "#${colors.error}";

      # Green
      color2 = "#${colors.success}";
      color10 = "#${colors.success}";

      # Yellow
      color3 = "#${colors.accent_gold}";
      color11 = "#${colors.accent_gold}";

      # Blue
      color4 = "#${colors.accent_cyan}";
      color12 = "#${colors.accent_cyan}";

      # Magenta
      color5 = "#${colors.accent_magenta}";
      color13 = "#${colors.accent_magenta}";

      # Cyan
      color6 = "#${colors.accent_cyan}";
      color14 = "#${colors.accent_cyan}";

      # White
      color7 = "#${colors.fg_normal}";
      color15 = "#${colors.fg_bright}";
    };

    shellIntegration.enableZshIntegration = true;

    keybindings = {
      "shift+enter" = "send_text all \\n";
    };
  };
}
