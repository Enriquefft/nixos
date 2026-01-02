# Hyprland Window Manager (System Configuration)
# User-level configuration in home-manager/hyprland.nix
{ ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };
}
