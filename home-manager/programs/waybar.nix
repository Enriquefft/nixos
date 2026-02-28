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
        modules-right = [ "mpris" "pulseaudio" "battery" "clock" "tray" ];

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

        # Battery
        "battery" = {
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-full = "󰁹 {capacity}%";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
          tooltip-format = "{timeTo}\nCapacity: {capacity}%\nHealth: {health}%";
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

      #battery {
        color: #${colors.fg_bright};
        padding: 0 12px;
      }

      #battery.charging, #battery.plugged, #battery.full {
        color: #${colors.success};
      }

      #battery.warning:not(.charging) {
        color: #${colors.accent_orange};
      }

      #battery.critical:not(.charging) {
        color: #${colors.error};
        animation: blink 1s ease-in-out infinite;
      }

      @keyframes blink {
        0% {
          opacity: 1;
        }
        50% {
          opacity: 0.5;
        }
        100% {
          opacity: 1;
        }
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
