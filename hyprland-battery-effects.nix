

{ config, lib, pkgs, ... }:

  with lib;

  let cfg = config.services.hyprlandBatteryEffects;
  in {
    options = {
      services.hyprlandBatteryEffects = {
        enable = mkOption {
          default = false;
          description = ''
            Whether to enable battery-based Hyprland visual effects management.
            Enables blur and shadow when battery is above threshold, disables 
  when below.
          '';
        };
        device = mkOption {
          default = "BAT0";
          description = ''
            Battery device to monitor.
          '';
        };
        threshold = mkOption {
          default = 90;
          description = ''
            Battery percentage threshold above which visual effects are 
  enabled.
          '';
        };
        checkInterval = mkOption {
          default = "2m";
          description = ''
            How often to check battery level (systemd time format).
          '';
        };
      };
    };

    config = mkIf cfg.enable {
      systemd.user.timers."hyprland-battery-effects" = {
        description = "Check battery level for Hyprland effects";
        timerConfig = {
          OnBootSec = "30s";
          OnUnitInactiveSec = cfg.checkInterval;
          Unit = "hyprland-battery-effects.service";
        };
        wantedBy = [ "timers.target" ];
      };

      systemd.user.services."hyprland-battery-effects" = {
        description = "Battery-based Hyprland visual effects manager";
        serviceConfig = {
          Type = "oneshot";
          PassEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
        };
        script = ''
          # Read battery status
          battery_capacity=$(${pkgs.coreutils}/bin/cat 
  /sys/class/power_supply/${cfg.device}/capacity 2>/dev/null || echo "100")

          # Check if Hyprland is running
          if ! ${pkgs.procps}/bin/pgrep -x Hyprland > /dev/null; then
            exit 0
          fi

          # Toggle effects based on battery level
          if [[ $battery_capacity -gt ${builtins.toString cfg.threshold} ]]; 
  then
            # Enable blur and shadow
            ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled true
            ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled true
          else
            # Disable blur and shadow
            ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled false
            ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled 
  false
          fi
        '';
      };
    };
  }
