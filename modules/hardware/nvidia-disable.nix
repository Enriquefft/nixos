# NVIDIA GPU Power Management
#
# Framework 16 has hybrid Intel + NVIDIA RTX 4070 Max-Q graphics.
# NVIDIA drivers are blacklisted from auto-loading but kept available on disk
# so gpu-toggle can modprobe them on demand for Ollama/CUDA workloads.
#
# At boot, udev rules set power/control=auto on the NVIDIA PCI devices.
# With no driver bound, the kernel transitions the GPU to D3cold (~0W).
{ config, pkgs, ... }:

let
  constants = import ../../shared/constants.nix;
in {
  # Blacklist drivers from auto-loading
  boot.extraModprobeConfig = ''
    blacklist nouveau
    blacklist nvidia_wmi_ec_backlight
    options nouveau modeset=0
  '';

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_wmi_ec_backlight"
  ];

  # Keep NVIDIA kernel modules available on disk for on-demand loading
  boot.extraModulePackages = [
    config.boot.kernelPackages.nvidiaPackages.stable
  ];

  # Enable NVIDIA hardware support (drivers blacklisted but userspace libs available)
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = false;  # Don't auto-load nvidia_drm
    open = false;  # Use proprietary driver
  };

  # Enable graphics/OpenGL support for CUDA
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # udev rules: set power/control=auto on NVIDIA VGA and HD Audio devices
  # With no driver bound, this allows the kernel to put the GPU into D3cold
  services.udev.extraRules = ''
    # NVIDIA VGA controller - enable runtime PM
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", ATTR{power/control}="auto"

    # NVIDIA HD Audio controller - enable runtime PM
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto"
  '';

  # Systemd oneshot to re-apply power/control=auto after TLP
  # TLP may reset power/control settings on PCI devices during its init
  systemd.services.nvidia-power-off = {
    description = "Ensure NVIDIA GPU power management is set to auto";
    after = [ "tlp.service" "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for dev in /sys/bus/pci/devices/${constants.gpu.pci.address} /sys/bus/pci/devices/${constants.gpu.pci.audioAddress}; do
        if [ -d "$dev" ]; then
          echo auto > "$dev/power/control"
        fi
      done
    '';
  };
}
