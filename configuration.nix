# Options: https://search.nixos.org/options
flake-overlays:
{
  config,
  inputs,
  pkgs,
  ...
}:

{

  imports = [
    ./hardware-configuration.nix
    ./applications.nix
    ./scripts.nix
    ./nix.nix
    ./suspend.nix
    ./hyprland-battery-effects.nix
    inputs.home-manager.nixosModules.default
  ];

  boot = {

    loader = {
      systemd-boot = {
        enable = true;
        editor = false;  # Disable boot entry editing for security
        consoleMode = "max";  # Use maximum resolution for boot menu
      };
      efi = {

        efiSysMountPoint = "/boot";

        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;

    kernelParams = [
      "i915.enable_psr=0"
      "quiet"           # Suppress most kernel messages
      "splash"          # Enable Plymouth splash screen
      "vt.global_cursor_default=0"  # Hide blinking cursor
      "rd.systemd.show_status=false"  # Hide systemd status during initrd
      "rd.udev.log_level=3"  # Reduce udev logging in initrd
      "udev.log_priority=3"  # Reduce udev logging after boot
    ];

    plymouth = {
      enable = true;
      font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
      themePackages = [ pkgs.adi1090x-plymouth-themes ];
      theme = "rings";  # Minimal theme matching research terminal aesthetic
    };
  };

  systemd.tmpfiles.rules = [
    # give hybridz read+write permits on /etc/nixos
    "A+       /etc/nixos -    -    -     -           u:hybridz:rwx"
  ];

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;

    # Open ports in the firewall.
    firewall.allowedTCPPorts = [
      80
      443
    ];
    firewall.allowedUDPPorts = [
      80
      443
    ];

    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];

  };

  # Set your time zone.

  time = {

    timeZone = "America/Lima";
    hardwareClockInLocalTime = true;
  };

  location = {
    # Hardcoded location settings saves the need for geolocation services.
    latitude = -12.11;
    longitude = -76.98;
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "es_PE.UTF-8/UTF-8"
    ];
  };

  console = {
    # Cyber Tardigrade TTY theme
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    earlySetup = true;
    useXkbConfig = true;

    # ANSI colors matching Cyber Tardigrade palette
    colors = [
      "0d0d1a"  # 0: black (bg_base)
      "d55a5a"  # 1: red (error)
      "5aaa7a"  # 2: green (success)
      "f0a050"  # 3: yellow (accent_gold)
      "5a8fba"  # 4: blue (accent_cyan)
      "b55a9a"  # 5: magenta (accent_magenta)
      "5a8fba"  # 6: cyan (accent_cyan)
      "a8a8c0"  # 7: white (fg_normal)
      "6b6b8a"  # 8: bright black (fg_dim)
      "ff8a8a"  # 9: bright red (terminal_error)
      "7fd4a8"  # 10: bright green (terminal_success)
      "ffbe78"  # 11: bright yellow (terminal_modified)
      "7eb3d4"  # 12: bright blue (terminal_cyan)
      "b55a9a"  # 13: bright magenta (accent_magenta)
      "7eb3d4"  # 14: bright cyan (terminal_cyan)
      "d4d4e8"  # 15: bright white (fg_bright)
    ];
  };

  qt = {
    enable = true;
    # TODO: rice xd
    # platformTheme = "gtk2";
    # style = "gtk2";
  };

  hardware = {

    # logitech = {
    #   wireless = {
    #     enable = true;
    #     enableGraphical = true;
    #   };
    #   lcd = {
    #     enable = true;
    #     startWhenNeeded = true;
    #   };
    # };

    bluetooth = {
      enable = true;
      powerOnBoot = false;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    cpu.intel.updateMicrocode = true;

    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [ vpl-gpu-rt ];

    };
    # nvidia = {
    #   modesetting.enable = true;
    #
    #   powerManagement = {
    #     enable = true;
    #     finegrained = true;
    #   };
    #
    #   prime = {
    #
    #     # NVIDIA PRIME Sync
    #     sync.enable = false;
    #
    #     # get bus id from `nix shell nixpkgs#pciutils -c lspci | grep ' VGA '`
    #     intelBusId = "PCI:0:2:0";
    #     nvidiaBusId = "PCI:1:0:0";
    #
    #     offload = {
    #       enable = true;
    #       enableOffloadCmd = true;
    #     };
    #
    #   };
    #
    #   open = true;
    #
    #   nvidiaSettings = true;
    #
    #   package = config.boot.kernelPackages.nvidiaPackages.stable;
    #
    # };

  };

  # DISABLE NVIDIA
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
  ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  users = {

    defaultUserShell = pkgs.zsh;
    groups = {
      plugdev = { };
    };

    users.hybridz = {
      isNormalUser = true;
      description = "Enrique Flores";
      extraGroups = [
        "wheel"
        "input"
        "networkmanager"
        "audio"
        "video"
        "docker"
        "plugdev"
      ];
    };

  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    users.hybridz = import ./home-manager/home.nix;
    verbose = true;

  };
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment = {
    localBinInPath = true;
    pathsToLink = [ "/share/zsh" ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ ];

    };

    overlays = flake-overlays;

  };

  programs = {

    steam = {

      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    gamemode.enable = false;

    dconf.enable = true;

    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    light = {
      enable = true;
    };

    hyprland = {
      withUWSM = true;

      enable = true;
      xwayland.enable = true;

    };

    zsh = {
      enable = true;

      # disable when using home-manager: https://github.com/nix-community/home-manager/issues/108
      enableCompletion = false;

    };

    firefox = {
      enable = true;
      preferences = {
        # "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.fullscreen.autohide" = false;
      };
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Core C/C++ runtime
        stdenv.cc.cc.lib

        # Common system libraries
        zlib
        openssl
        curl

        # Graphics/GUI (for Electron apps like Slack, Discord, VSCode)
        glib
        nss
        nspr
        dbus
        atk
        cups
        libdrm
        gtk3
        pango
        cairo
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
        mesa
        expat
        alsa-lib

        # Development tools common deps
        libffi
        ncurses
        readline
      ];
    };

  };

  services = {

    pulseaudio.enable = false;

    keyd = {
      enable = true;

      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              capslock = "esc";

              escape = "capslock";
              f5 = "2";

            };
          };
        };
      };

    };

    envfs.enable = true;

    # # Remove NVIDIA USB xHCI Host Controller devices, if present
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    # # Remove NVIDIA USB Type-C UCSI devices, if present
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    # # Remove NVIDIA Audio devices, if present
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    # # Remove NVIDIA VGA/3D controller devices
    # ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
    udev.extraRules = ''

      # ZSA/Oryx

      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"


    '';

    upower.enable = true;

    batteryNotifier = {
      enable = true;
      device = "BAT0";
      notifyCapacity = 10;
      suspendCapacity = 5;
    };

    hyprlandBatteryEffects = {
      enable = true;
      device = "BAT0";
      threshold = 90;
      checkInterval = "2m";
    };

    dbus = {
      enable = true;
    };

    flatpak.enable = true;

    blueman.enable = true;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
    postgresql = {
      enable = false;
      ensureDatabases = [ "hybridz" ];

      ensureUsers = [
        {
          name = "hybridz";
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            createrole = true;
            createdb = true;
            bypassrls = true;
            "inherit" = true;
            replication = true;

          };
        }
      ];

      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
    };

    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 5500;
        night = 3700;
      };
    };

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    # touchpad support
    libinput.enable = true;

    # displayManager.sddm.wayland.enable = true;

    # Configure keymap in X11
    xserver = {
      # videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
        variant = "intl";
        options = "caps:swapescape";
      };

    };

    pipewire = {

      enable = true;

      pulse.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack.enable = true;

    };

    # prevent overheating on intel CPU
    thermald.enable = true;

    tlp = {
      enable = true;
      settings = {
        # Platform
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 85; # 80 and above it stops charging
      };
    };

    #   auto-cpufreq = {
    #     enable = true;
    #     settings = {
    #       battery = {
    #         governor = "powersave";
    #         turbo = "never";
    #       };
    #       charger = {
    #         governor = "performance";
    #         turbo = "auto";
    #       };
    #     };
    #   };
  };

  virtualisation = {
    docker = {
      enable = true;
    };

  };

  security = {

    polkit.enable = true;

    rtkit.enable = true;

    pam.services.login.enableGnomeKeyring = true;

    sudo.enable = true; # Enabled to be used with sudoedit (svim alias)

    doas = {

      enable = true;
      extraRules = [

        {
          users = [ "hybridz" ];
          keepEnv = true;
          persist = true;

        }

      ];

    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system = {
    # autoUpgrade.enable = true;
    stateVersion = "24.05"; # DONT TOUCH
  };

}
