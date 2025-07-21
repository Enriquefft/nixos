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

      postman
      unrar-wrapper
      openvpn
      zoom-us

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
      pokemonsay
      gnumake
      unzip
      zip
      p7zip
      csvlens
      mlocate
      lsof

      # ZSA Keyboard
      keymapp

      # Desktop Environment Tools
      xfce.thunar
      pavucontrol
      pamixer

      # Media Applications
      vlc
      obs-studio
      gimp

      # Browsers
      (pkgs.wrapFirefox
        (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
      google-chrome

      # Communication Tools
      discord
      element-desktop

      # Office Suite
      libreoffice-qt

      # Development Tools
      # zed-editor
      pgcli
      gh
      # unityhub
      awscli2
      openssl
      # biome
      # ollama
      code-cursor-fhs

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
      adwaita-icon-theme
      solaar
      certbot-full
      # pymol

      # Gaming
      mangohud
      protonup
      lutris
      heroic
      bottles
      # cockatrice
      prismlauncher
      modrinth-app
      # ferium
      pokemmo-installer
      # lime3ds
      # ryujinx
      netflix

      xournalpp

    ];
  };
}
