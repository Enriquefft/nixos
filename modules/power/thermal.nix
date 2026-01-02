# Thermal Management
# CPU thermal protection and power management
{ ... }:

{
  # Prevent overheating on Intel CPU
  services.thermald.enable = true;

  # Global power management settings
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };
}
