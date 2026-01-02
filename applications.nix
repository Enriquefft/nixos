{ pkgs, ... }:

{

  environment = rec {

    # Generates a text file listing all installed system packages, sorted and unique.
    etc."current-system-packages".text =
      let
        packages = builtins.map (p: "${p.name}") systemPackages;
        sortedUnique = builtins.sort builtins.lessThan (pkgs.lib.lists.unique packages);
        formatted = builtins.concatStringsSep "\n" sortedUnique;
      in
      formatted;

    systemPackages = with pkgs; [
      whisper-cpp

      nodejs
      postman
      unrar-wrapper
      openvpn
      zoom-us
      protonvpn-gui
      komikku
      # System information
      hwinfo
      pciutils
      lshw
      dmidecode
      inxi

      uv
      jq

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
      trash-cli

      # ZSA Keyboard
      keymapp

      # Desktop Environment Tools
      xfce.thunar
      pavucontrol
      pamixer
      gnome-keyring
      seahorse

      # Media Applications
      vlc
      obs-studio
      gimp
      ffmpeg

      # Browsers
      (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
      google-chrome

      # Communication Tools
      discord
      # element-desktop

      # Office Suite
      libreoffice-still

      # Development Tools
      # zed-editor
      pgcli
      gh
      # unityhub
      # awscli2
      openssl
      # ollama
      code-cursor-fhs
      claude-code
      act

      # Academia Tools
      obsidian

      # Custom Applications
      (import ./packages/whispering.nix { inherit pkgs; })

      # Design Tools
      figma-linux

      # Hyprland Utilities
      hyprshot
      hyprpicker
      hyprlock
      hypridle
      hyprpaper
      hyprsunset

      # Desktop Tools
      wlogout
      cliphist
      grim
      slurp

      # CLI Tools
      yazi
      btop
      fd
      lazygit

      # System Utilities
      brightnessctl
      playerctl

      # Theming Tools
      nwg-look
      libsForQt5.qt5ct
      kdePackages.qt6ct

      # Media
      (import ./packages/riff.nix {
        inherit (pkgs)
          lib
          stdenv
          fetchFromGitHub
          rustPlatform
          meson
          ninja
          pkg-config
          wrapGAppsHook4
          blueprint-compiler
          desktop-file-utils
          gtk4
          libadwaita
          gst_all_1
          alsa-lib
          openssl
          libpulseaudio
          pipewire
          ;
      })
      cava

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
      protonup-ng
      lutris
      heroic
      bottles
      # cockatrice
      prismlauncher
      # modrinth-app
      # ferium
      pokemmo-installer
      # lime3ds
      # ryujinx

      xournalpp

    ];
  };
}
