# NVIDIA GPU Disabled for Maximum Battery Life
#
# Framework 13 has hybrid Intel + NVIDIA graphics. NVIDIA is blacklisted because:
# - Intel iGPU handles all display output efficiently
# - NVIDIA dGPU consumes ~10-15W idle (significant battery drain)
# - PRIME offload adds complexity for minimal benefit on this hardware
# - Power savings: ~2-3 hours additional battery life
#
# To re-enable: Remove this module import from configuration.nix
{ ... }:

{
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
  ];
}
