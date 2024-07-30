{ pkgs, ... }:

{

  # TODO: Fix pkgs listing
  environment = rec {

    etc."current-system-packages".text = let
      packages = builtins.map (p: "${p.name}") systemPackages;
      sortedUnique =
        builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in formatted;
    systemPackages = with pkgs; [

      gparted

      xfce.thunar

      obs-studio

      figma-linux
      vlc

      (pkgs.wrapFirefox
        (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
      google-chrome

      hyprpicker

      killall

      discord

hwinfo

pciutils

      mako

      wget
      vim
      git
      file

      glib

      binutils
      eza
      wl-clipboard

      bat
      ripgrep
      fzf
      dconf

      pass

      hyprshot

      zed-editor

      pgcli

      unityhub

      xdg-utils

      unzip

      hyprpaper

      element-desktop-wayland

      tree
      fastfetch
      gh
      gnumake
      pamixer
      pavucontrol

      libreoffice-qt
    ];
  };
}
