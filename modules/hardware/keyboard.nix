# ZSA Voyager keyboard configuration via oryx-bench
{ config, pkgs, inputs, ... }:

{
  programs.oryx-bench = {
    enable = true;
    package = inputs.oryx-bench.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Keyboard builds disabled — oryx-bench build requires a writable
    # directory and cannot run inside the nix sandbox.  Use `oryx-bench
    # build` manually or `flash-voyager` directly instead.
    # keyboards.voyager = {
    #   enable = true;
    #   source = /etc/nixos/keyboards/voyager;
    #   version = "0.1.0";
    # };

    enableFlashScripts = false;
  };

  # HID/udev rules for keyboard access without sudo
  # Allows the 'dialout' group to flash keyboards
  services.udev.extraRules = ''
    # ZSA Voyager and other ZSA keyboards (USB vendor ID 0x3297)
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666"
    KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE:="0666", GROUP:="dialout"
  '';

  # Make sure dialout group exists and user is a member
  users.groups.dialout = { };
  users.users.hybridz.extraGroups = [ "dialout" "docker" ];
}
