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
    # Ensure libsmbios is available for battery charge control
    environment.systemPackages = [ pkgs.libsmbios ];

    # NOTE: dell-battery-charge-mode service disabled — battery physically removed (swollen)
    # Restore when replacement battery is installed (use libsmbios smbios-battery-ctl)

    # TLP — AC (desktop) and BAT (server mode) profiles
    # Switch profiles with: sudo tlp ac | sudo tlp bat
    services.tlp = {
      enable = true;
      settings = {
        # === AC profile (desktop mode — full performance) ===
        PLATFORM_PROFILE_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_BOOST_ON_AC = 1;
        WIFI_PWR_ON_AC = "off";
        RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_AC = "on";
        SATA_LINKPWR_ON_AC = "max_performance";
        SOUND_POWER_SAVE_ON_AC = 0;

        # === BAT profile (server mode — minimal power) ===
        PLATFORM_PROFILE_ON_BAT = "low-power";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 30;
        CPU_BOOST_ON_BAT = 0;
        WIFI_PWR_ON_BAT = "off";  # Keep off — Tailscale stability > tiny savings
        RUNTIME_PM_ON_BAT = "auto";
        AHCI_RUNTIME_PM_ON_BAT = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
        SOUND_POWER_SAVE_ON_BAT = 1;

        # === Shared settings ===
        USB_AUTOSUSPEND = 0;
        SOUND_POWER_SAVE_CONTROLLER = "N";
      };
    };

    # Battery services disabled — no battery installed
    services.batteryNotifier.enable = false;
  };
}
