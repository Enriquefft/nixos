# Notification Service (Mako)
# Desktop notifications with Cyber Tardigrade theme
{ ... }:

let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
  services.mako = {
    enable = true;

    settings = {
      # Base settings
      anchor = "top-right";
      border-radius = 8;
      border-size = 2;
      default-timeout = 10000;
      icons = true;
      layer = "overlay";
      max-visible = 3;
      padding = "10";
      width = 300;

      # Base colors (Cyber Tardigrade theme)
      background-color = "#${colors.bg_elevated}";
      text-color = "#${colors.fg_bright}";
      border-color = "#${colors.border}";
    };

    # Urgency-specific settings
    extraConfig = ''
      [urgency=low]
      border-color=#${colors.accent_cyan}

      [urgency=normal]
      border-color=#${colors.accent_purple}

      [urgency=critical]
      border-color=#${colors.accent_orange}
      background-color=#${colors.bg_elevated}
      default-timeout=0
    '';
  };
}
