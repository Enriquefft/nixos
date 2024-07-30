{ pkgs, ... }:

{

  # TODO: Fix pkgs listing
  environment = rec {

    # Generates a text file listing all installed system packages, sorted and unique.
    etc."current-system-packages".text = let
      packages = builtins.map (p: "${p.name}") systemPackages;
      sortedUnique =
        builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in formatted;

    systemPackages = with pkgs; [

      # System Utilities
      gparted
      hwinfo
      pciutils
      killall
      wget
      vim
      git
      file
      binutils
      eza
      wl-clipboard
      bat
      ripgrep
      fzf
      dconf
      pass
      tree
      fastfetch
      gnumake

      # Desktop Environment Tools
      xfce.thunar
      hyprpicker
      mako
      wl-clipboard
      pavucontrol
      pamixer

      # Media Applications
      vlc
      obs-studio

      # Browsers
      (pkgs.wrapFirefox
        (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
      google-chrome

      # Communication Tools
      discord
      element-desktop-wayland

      # Office Suite
      libreoffice-qt

      # Development Tools
      zed-editor
      pgcli
      gh

      # Design Tools
      figma-linux

      # Unity Hub
      unityhub

      # Archive Tools
      unzip

      # Hyprland Utilities
      hyprshot
      hyprpaper

      # Miscellaneous
      glib
      xdg-utils
    ];
  };
}
