{ config, pkgs, lib, ... }:
let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
  programs.wofi = {
    enable = true;

    settings = {
      width = 600;
      height = 400;
      show = "drun";
      prompt = "Search...";
      allow_images = true;
      insensitive = true;
    };

    style = ''
      window {
        background: #${colors.bg_surface}f2;  /* f2 = 95% opacity */
        border: 2px solid #${colors.border};
        border-radius: 8px;
      }

      #input {
        background: #${colors.bg_base};
        color: #${colors.fg_bright};
        border: none;
        padding: 12px;
        margin: 8px;
        border-radius: 4px;
      }

      #entry {
        padding: 8px;
        color: #${colors.fg_bright};
      }

      #entry:selected {
        background: #${colors.accent_orange};
        color: #${colors.bg_base};
        border-radius: 4px;
      }

      #text {
        color: #${colors.fg_bright};
      }

      #text:selected {
        color: #${colors.bg_base};
      }
    '';
  };
}
