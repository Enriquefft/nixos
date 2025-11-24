# Options: https://search.nixos.org/options
flake-overlays:
{ config, inputs, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ./applications.nix
    ./scripts.nix
    ./nix.nix
    inputs.home-manager.nixosModules.default
  ];

  boot = {

    loader = {
      systemd-boot = { enable = true; };
      efi = {

        efiSysMountPoint = "/boot";

        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;

    kernelParams = [ "i915.enable_psr=0" ];
    # plymouth = {
    #   enable = true;
    #   font =
    #     "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf";
    #   themePackages = [ pkgs.catppuccin-plymouth ];
    #   theme = "catppuccin-macchiato";
    # };
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
    firewall.allowedTCPPorts = [ 80 443 ];
    firewall.allowedUDPPorts = [ 80 443 ];

    nameservers = [ "8.8.8.8" "8.8.4.4" ];

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
    supportedLocales = [ "en_US.UTF-8/UTF-8" "es_PE.UTF-8/UTF-8" ];
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkb.options in tty.
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

  boot.blacklistedKernelModules =
    [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  users = {

    defaultUserShell = pkgs.zsh;
    groups = { plugdev = { }; };

    users.hybridz = {
      isNormalUser = true;
      description = "Enrique Flores";
      extraGroups =
        [ "wheel" "input" "networkmanager" "audio" "video" "docker" "plugdev" ];
    };

  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    users.hybridz = import ./home-manager/home.nix;
    verbose = true;

  };
  fonts.packages = [ pkgs.nerd-fonts.fira-code ];

  environment = {
    localBinInPath = true;
    pathsToLink = [ "/share/zsh" ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS =
        "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "qtwebengine-5.15.19" ];

    };

    overlays = flake-overlays;

  };

  programs = {

    steam = {

      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall =
        true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall =
        true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall =
        true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    gamemode.enable = false;

    dconf.enable = true;

    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    light = { enable = true; };

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

    dbus = { enable = true; };

    flatpak.enable = true;

    blueman.enable = true;

    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "hybridz" ];

      ensureUsers = [{
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
      }];

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
    docker = { enable = true; };

  };

  security = {

    polkit.enable = true;

    rtkit.enable = true;

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
