# Hyprland Window Manager Configuration
# Entry point - imports all Hyprland configuration modules
{ pkgs, ... }:

let
  constants = import ../../../shared/constants.nix;
in {
  imports = [
    ./appearance.nix
    ./input.nix
    ./keybinds.nix
    ./windowrules.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false;  # Using UWSM instead

    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,${toString constants.display.scale}";

      # Startup applications
      exec-once = [
        "uwsm app -- firefox"
        "uwsm app -- waybar"
        "uwsm app -- hyprpaper"
        "uwsm app -- wl-paste --watch cliphist store"
        "uwsm app -- ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
      ];

      xwayland.force_zero_scaling = true;

      # Miscellaneous settings
      misc = {
        force_default_wallpaper = "-1";
        vfr = true;
      };

      # Dwindle layout
      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
      };

      # Main modifier key
      "$mainMod" = "SUPER";
    };
  };
}
