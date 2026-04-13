{ ... }:
let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
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
        modules-right = [ "mpris" "pulseaudio" "clock" "tray" ];

        # Custom logo module
        "custom/logo" = {
          format = "󰣇";
          on-click = "wofi --show drun";
        };

        # Workspaces
        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "🦞";
            "9" = "9";
            default = "{id}";
          };
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
          format-wifi = "󰤨 {essid} ({signalStrength}%) {bandwidthDownBits} ↓ {bandwidthUpBits} ↑";
          format-ethernet = "󰈀 {ifname} {bandwidthDownBits} ↓ {bandwidthUpBits} ↑";
          format-disconnected = "󰤭 Disconnected";
          tooltip-format-wifi = "{essid} via {ifname}\nSignal: {signalStrength}%\nFrequency: {frequency} GHz";
          tooltip-format-ethernet = "Connected via {ifname}";
          interval = 1;
        };

        # MPRIS (media player)
        "mpris" = {
          format = "♪ {title} - {artist}";
          max-length = 40;
        };

        # PulseAudio/PipeWire volume
        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = " {volume}%";
          format-icons = {
            headphone = "";
            headset = "";
            default = ["" "" ""];
          };
          scroll-step = 5;
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
          tooltip-format = "{desc}\nVolume: {volume}%";
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

      #pulseaudio {
        color: #${colors.accent_magenta};
        padding: 0 12px;
      }

      #pulseaudio.muted {
        color: #${colors.fg_dim};
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
