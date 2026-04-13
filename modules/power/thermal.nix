# Thermal Management
# CPU thermal protection and power management
{ ... }:

{
  # Prevent overheating on Intel CPU
  services.thermald.enable = true;

  # Global power management settings
  powerManagement = {
    enable = true;
    # powersave governor still boosts on demand (Intel HWP); idles much cooler
    cpuFreqGovernor = "powersave";
  };

  # Dell platform_profile: cool quiet balanced balanced-performance performance custom
  # "balanced" keeps fans reasonable while thermal paste is degraded
  systemd.tmpfiles.rules = [
    "w /sys/firmware/acpi/platform_profile - - - - balanced"
  ];

  # Lid switch: lock session instead of suspend (AC-only, no battery)
  services.logind.settings.Login = {
    HandleLidSwitch = "lock";
    HandleLidSwitchExternalPower = "lock";
  };
}
