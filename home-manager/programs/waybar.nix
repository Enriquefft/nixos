{ ... }:
let
  colors = (import ../colors.nix).cyberTardigrade;
in {
  programs.waybar = {
    enable = true;

    settings = {
      bar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 5;

        # Module layout per rice.md
        modules-left = [ "custom/logo" "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "cpu" "memory" "network" ];
        modules-right = [ "mpris" "clock" "tray" ];

        # Custom logo module
        "custom/logo" = {
          format = "󰣇";
          on-click = "wofi --show drun";
        };

        # Workspaces
        "hyprland/workspaces" = {
          format = "{id}";
        };

        # Window title
        "hyprland/window" = {
          max-length = 50;
        };

        # CPU
        "cpu" = {
          format = " {usage}%";
          on-click = "kitty -e btop";
        };

        # Memory
        "memory" = {
          format = " {percentage}%";
        };

        # Network
        "network" = {
          format = "󰈀 {bandwidthDownBits} ↓ {bandwidthUpBits} ↑";
          interval = 1;
        };

        # MPRIS (media player)
        "mpris" = {
          format = "♪ {title} - {artist}";
          max-length = 40;
        };

        # Clock
        "clock" = {
          format = "󰃰 {:%b %d  %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        # Tray
        "tray" = {
          icon-size = 21;
          spacing = 8;
        };
      };
    };

    # Custom CSS styling
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }

      window#waybar {
        background: #${colors.bg_surface};
        color: #${colors.fg_normal};
      }

      #workspaces button {
        color: #${colors.fg_dim};
        padding: 0 8px;
      }

      #workspaces button.active {
        background: #${colors.accent_orange};
        color: #${colors.bg_base};
        border-radius: 4px;
        font-weight: bold;
      }

      #cpu, #memory, #network {
        padding: 0 12px;
        color: #${colors.fg_bright};
      }

      #mpris {
        color: #${colors.accent_cyan};
      }

      #clock {
        color: #${colors.accent_gold};
      }

      #tray {
        padding: 0 8px;
      }

      #custom-logo {
        padding: 0 12px;
        font-size: 16px;
      }

      #window {
        margin: 0 8px;
      }
    '';
  };
}
