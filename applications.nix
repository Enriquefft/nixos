{ pkgs, antigravity, ... }:

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
      # ─────────────────────────────────────────────────────────
      # Core System Utilities
      # ─────────────────────────────────────────────────────────
      git
      wget
      vim
      killall
      brightnessctl
      playerctl
      gparted

      # File Management
      file
      tree
      eza
      unzip
      zip
      p7zip
      unrar-wrapper
      trash-cli
      mlocate

      # System Information
      hwinfo
      pciutils
      lshw
      dmidecode
      inxi
      lsof
      fastfetch
      powertop

      # ─────────────────────────────────────────────────────────
      # CLI Tools
      # ─────────────────────────────────────────────────────────
      bat
      ripgrep
      fzf
      fd
      zoxide
      jq
      csvlens
      yazi
      btop
      lazygit

      # ─────────────────────────────────────────────────────────
      # Development Tools
      # ─────────────────────────────────────────────────────────
      binutils
      gnumake
      openssl
      nodejs
      uv

      # Development Applications
      code-cursor-fhs
      # claude-code
      antigravity
      (pkgs.writeShellScriptBin "opencode" ''
        exec /home/hybridz/.opencode/bin/opencode "$@"
      '')
      (pkgs.writeShellScriptBin "gemini" ''
        exec npx @google/gemini-cli "$@"
      '')
      postman
      pgcli
      gh
      act

      # ─────────────────────────────────────────────────────────
      # Desktop Environment
      # ─────────────────────────────────────────────────────────
      # Hyprland Utilities
      hyprshot
      hyprpicker
      hyprlock
      hypridle
      hyprpaper
      hyprsunset
      wlogout

      # Desktop Tools
      xfce.thunar
      cliphist
      grim
      slurp
      wl-clipboard

      # Audio Control
      pavucontrol
      pamixer

      # Theming & Appearance
      nwg-look
      libsForQt5.qt5ct
      kdePackages.qt6ct
      adw-gtk3
      gnome-themes-extra
      adwaita-icon-theme

      # System Integration
      dconf
      glib
      xdg-utils
      libnotify
      gnome-keyring
      seahorse
      pass

      # ─────────────────────────────────────────────────────────
      # Browsers
      # ─────────────────────────────────────────────────────────
      (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
      google-chrome

      # ─────────────────────────────────────────────────────────
      # Communication
      # ─────────────────────────────────────────────────────────
      discord
      zoom-us

      # ─────────────────────────────────────────────────────────
      # Media & Content Creation
      # ─────────────────────────────────────────────────────────
      vlc
      gimp
      ffmpeg
      whisper-cpp
      cava
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

      # ─────────────────────────────────────────────────────────
      # Productivity
      # ─────────────────────────────────────────────────────────
      libreoffice-still
      obsidian
      xournalpp
      komikku

      # ─────────────────────────────────────────────────────────
      # Design & Creative Tools
      # ─────────────────────────────────────────────────────────
      figma-linux

      # ─────────────────────────────────────────────────────────
      # Gaming
      # ─────────────────────────────────────────────────────────
      mangohud
      protonup-ng
      lutris
      heroic
      bottles
      prismlauncher
      pokemmo-installer

      # ─────────────────────────────────────────────────────────
      # Hardware & Peripherals
      # ─────────────────────────────────────────────────────────
      keymapp # ZSA Keyboard
      solaar # Logitech devices

      # ─────────────────────────────────────────────────────────
      # Security & Networking
      # ─────────────────────────────────────────────────────────
      openvpn
      protonvpn-gui
      certbot-full

      # ─────────────────────────────────────────────────────────
      # Custom Packages
      # ─────────────────────────────────────────────────────────
      (import ./packages/whispering.nix { inherit pkgs; })

      # ─────────────────────────────────────────────────────────
      # Fun Stuff
      # ─────────────────────────────────────────────────────────
      pokemonsay

    ];
  };
}
