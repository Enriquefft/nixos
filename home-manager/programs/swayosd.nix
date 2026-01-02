{ config, pkgs, lib, ... }:
let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
  services.swayosd = {
    enable = true;
    topMargin = 0.9;
    stylePath = "${config.xdg.configHome}/swayosd/style.css";
  };

  xdg.configFile."swayosd/style.css".text = ''
    /* Cyber Tardigrade Theme for SwayOSD */

    window {
      background: #${colors.bg_elevated}ee;
      border-radius: 8px;
      padding: 20px;
    }

    #osd {
      border: 2px solid #${colors.accent_orange};
      border-radius: 8px;
      padding: 12px;
    }

    progressbar {
      background: linear-gradient(to right, #${colors.accent_orange}, #${colors.accent_gold});
      border-radius: 4px;
      min-height: 8px;
    }

    progressbar trough {
      background: #${colors.bg_base};
      border-radius: 4px;
    }

    label {
      color: #${colors.fg_bright};
      font-family: "JetBrainsMono Nerd Font";
      font-size: 14px;
      font-weight: bold;
    }
  '';
}
