{ config, pkgs, lib, ... }: {

  programs.wofi = {
    enable = true;
    # package = pkgs.rofi-wayland;
    # theme = "android_notification";
  };

}
