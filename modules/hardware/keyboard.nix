# ZSA Voyager keyboard configuration via oryx-bench
{ config, pkgs, ... }:

{
  programs.oryx-bench = {
    enable = true;

    keyboards.voyager = {
      enable = true;
      source = /etc/nixos/keyboards/voyager;
      version = "0.1.0";
    };

    enableFlashScripts = true;
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
