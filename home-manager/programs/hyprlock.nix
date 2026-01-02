{ config, pkgs, ... }:
let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 10;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "${config.home.homeDirectory}/Pictures/walppaper.png";
          blur_passes = 3;
          blur_size = 6;
        }
      ];

      input-field = [
        {
          size = "300, 50";
          position = "0, 80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(${colors.fg_bright})";
          inner_color = "rgb(${colors.bg_base})";
          outer_color = "rgb(${colors.accent_orange})";
          outline_thickness = 2;
          placeholder_text = ''<span foreground="##${colors.fg_normal}">Password...</span>'';
          shadow_passes = 2;
        }
      ];

      label = [
        # Time
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<b><big> $(date +"%H:%M") </big></b>"'';
          color = "rgb(${colors.fg_bright})";
          font_size = 64;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -150";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "";
          text = ''cmd[update:18000000] echo "<b> $(date +'%A, %-d %B %Y') </b>"'';
          color = "rgb(${colors.fg_bright})";
          font_size = 24;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -70";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
