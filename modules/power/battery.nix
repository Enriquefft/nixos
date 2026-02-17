# Battery Management - Unified configuration for all battery-related features
# Consolidates TLP charge thresholds, low battery notifications, and visual effects
{ config, lib, pkgs, ... }:

with lib;

let
  constants = import ../../shared/constants.nix;

  # Battery notifier configuration
  cfgNotifier = config.services.batteryNotifier;

  # Hyprland battery effects configuration
  cfgEffects = config.services.hyprlandBatteryEffects;
in {
  options = {
    services.batteryNotifier = {
      enable = mkOption {
        default = false;
        description = "Whether to enable battery notifier.";
      };
      device = mkOption {
        default = "BAT0";
        description = "Device to monitor.";
      };
      notifyCapacity = mkOption {
        default = 10;
        description = "Battery level at which a notification shall be sent.";
      };
      suspendCapacity = mkOption {
        default = 5;
        description = "Battery level at which a suspend unless connected shall be sent.";
      };
    };

    services.hyprlandBatteryEffects = {
      enable = mkOption {
        default = false;
        description = ''
          Whether to enable battery-based Hyprland visual effects management.
          Enables blur and shadow when battery is above threshold, disables when below.
        '';
      };
      device = mkOption {
        default = "BAT0";
        description = "Battery device to monitor.";
      };
      threshold = mkOption {
        default = 90;
        description = "Battery percentage threshold above which visual effects are enabled.";
      };
      checkInterval = mkOption {
        default = "2m";
        description = "How often to check battery level (systemd time format).";
      };
    };
  };

  config = {
    # TLP battery charge thresholds (extends battery lifespan)
    services.tlp = {
      enable = true;
      settings = {
        # Platform
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 80;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        # Disable turbo boost - reduces heat significantly
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;

        # Battery charge thresholds - balances availability with longevity
        START_CHARGE_THRESH_BAT0 = constants.battery.charge.start;  # Start charging below 40%
        STOP_CHARGE_THRESH_BAT0 = constants.battery.charge.stop;    # Stop charging at 85%

        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # USB autosuspend
        USB_AUTOSUSPEND = 1;

        # Runtime Power Management for PCI(e) devices
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # NVMe/SATA power management
        AHCI_RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
        SATA_LINKPWR_ON_AC = "max_performance";

        # Sound power saving
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";
      };
    };

    # Low battery notifications and auto-suspend
    services.batteryNotifier = {
      enable = true;
      device = constants.battery.device;
      notifyCapacity = constants.battery.notify;    # 10%
      suspendCapacity = constants.battery.suspend;  # 5%
    };

    systemd.user = mkMerge [
      # Battery notifier service
      (mkIf cfgNotifier.enable {
        timers."lowbatt" = {
          description = "check battery level";
          timerConfig = {
            OnBootSec = "1m";
            OnUnitInactiveSec = "2m";
            Unit = "lowbatt.service";
          };
          wantedBy = [ "timers.target" ];
        };
        services."lowbatt" = {
          description = "battery level notifier";
          serviceConfig.PassEnvironment = "DISPLAY";
          script = ''
            export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfgNotifier.device}/capacity)
            export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfgNotifier.device}/status)

            if [[ $battery_capacity -le ${builtins.toString cfgNotifier.notifyCapacity}
                && $battery_status = "Discharging" ]]; then
                ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Low" "You should probably plug-in."
            fi

            if [[ $battery_capacity -le ${builtins.toString cfgNotifier.suspendCapacity}
                && $battery_status = "Discharging" ]]; then
                ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Critically Low" "Computer will suspend in 60 seconds."
                sleep 60s  # 60-second grace period - allows user to plug in charger

                battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfgNotifier.device}/status)
                if [[ $battery_status = "Discharging" ]]; then
                    systemctl suspend
                fi
            fi
          '';
        };
      })

      # Battery temperature monitor (warns if battery overheats)
      {
        timers."battery-temp-monitor" = {
          description = "Monitor battery temperature";
          timerConfig = {
            OnBootSec = "2m";
            OnUnitInactiveSec = "5m";
            Unit = "battery-temp-monitor.service";
          };
          wantedBy = [ "timers.target" ];
        };
        services."battery-temp-monitor" = {
          description = "Battery temperature warning";
          serviceConfig.PassEnvironment = "DISPLAY";
          script = ''
            temp_raw=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${constants.battery.device}/temp 2>/dev/null || echo "0")
            # temp is in tenths of degrees C (e.g. 361 = 36.1°C)
            temp_threshold=450  # 45.0°C

            if [[ $temp_raw -ge $temp_threshold ]]; then
              temp_display=$((temp_raw / 10))
              ${pkgs.libnotify}/bin/notify-send --urgency=critical --icon=dialog-warning \
                "Battery Overheating" \
                "Battery temperature is ''${temp_display}°C. Consider reducing load or shutting down."
            fi
          '';
        };
      }

      # Hyprland visual effects (disable blur/shadow on battery)
      (mkIf cfgEffects.enable {
        services.hyprlandBatteryEffects = {
          enable = true;
          device = constants.battery.device;
          threshold = constants.battery.effects;  # 90%
          checkInterval = "2m";
        };

        timers."hyprland-battery-effects" = {
          description = "Check battery level for Hyprland effects";
          timerConfig = {
            OnBootSec = "30s";
            OnUnitInactiveSec = cfgEffects.checkInterval;
            Unit = "hyprland-battery-effects.service";
          };
          wantedBy = [ "timers.target" ];
        };

        services."hyprland-battery-effects" = {
          description = "Battery-based Hyprland visual effects manager";
          serviceConfig = {
            Type = "oneshot";
            PassEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
          };
          script = ''
            # Read battery status
            battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${cfgEffects.device}/capacity 2>/dev/null || echo "100")

            # Check if Hyprland is running
            if ! ${pkgs.procps}/bin/pgrep -x Hyprland > /dev/null; then
              exit 0
            fi

            # Toggle effects based on battery level
            if [[ $battery_capacity -gt ${builtins.toString cfgEffects.threshold} ]]; then
              # Enable blur and shadow
              ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled true
              ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled true
            else
              # Disable blur and shadow
              ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled false
              ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled false
            fi
          '';
        };
      })
    ];
  };
}
