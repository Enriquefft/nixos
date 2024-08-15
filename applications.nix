{ pkgs, ... }:

{

  environment = rec {

    # Generates a text file listing all installed system packages, sorted and unique.
    etc."current-system-packages".text = let
      packages = builtins.map (p: "${p.name}") systemPackages;
      sortedUnique =
        builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
      formatted = builtins.concatStringsSep "\n" sortedUnique;
    in formatted;

    systemPackages = with pkgs; [

      # System information
      hwinfo
      pciutils
      lshw
      dmidecode
      inxi

      # System Utilities
      gparted
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
      unzip

      # Desktop Environment Tools
      xfce.thunar
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
      unityhub
      awscli2
      openssl

      # Academia Tools
      obsidian

      # Design Tools
      figma-linux

      # Hyprland Utilities
      hyprshot
      hyprpicker

      # Miscellaneous
      glib
      xdg-utils
      libnotify
      gnome.adwaita-icon-theme
      solaar
      ventoy-full

      # Gaming
      mangohud
      protonup
      lutris
      heroic
      bottles

    xournal
    ];
  };
}
