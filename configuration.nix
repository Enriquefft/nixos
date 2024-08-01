# Options: https://search.nixos.org/options
{ inputs, pkgs, ... }:

{

  imports = [
    ./hardware-configuration.nix
    ./suspend.nix
    ./applications.nix
    ./scripts.nix
    ./nix.nix
    inputs.home-manager.nixosModules.default
  ];

  boot = {

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

  };

  systemd.tmpfiles.rules = [
    # give hybridz read+write permits on /etc/nixos
    "A+       /etc/nixos -    -    -     -           u:hybridz:rwx"
  ];

  xdg = {
    autostart.enable = true;
    portal = {
      extraPortals = [
        # https://wiki.hyprland.org/hyprland-wiki/pages/Useful-Utilities/Hyprland-desktop-portal/
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];

  };

  # Set your time zone.
  time.timeZone = "America/Lima";
  location = {
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
    platformTheme = "gtk2";
    style = "gtk2";
  };

  hardware = {

    pulseaudio.enable = false;
    bluetooth = {

      enable = true;
      powerOnBoot = false;
    };

    cpu.intel.updateMicrocode = true;

    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    # TODO: configure nvidia
    #
    # graphics = {
    #   enable = true;
    #   enable32Bit = true;
    # };
    # nvidia = {
    #   modesetting.enable = true;
    #
    #   powerManagement = {
    #
    #     enable = false;
    #
    #     finegrained = true;
    #   };
    #
    #   prime = {
    #
    #     intelBusId = "PCI:0:2:0";
    #     nvidiaBusId = "PCI:1:0:0";
    #
    #     offload = {
    #
    #       enable = true;
    #       enableOffloadCmd = true;
    #     };
    #
    #   };
    #
    #   open = false;
    #
    #   nvidiaSettings = true;
    #
    #   package = config.boot.kernelPackages.nvidiaPackages.stable;
    #
    # };

  };

  powerManagement.enable = true;

  users = {

    defaultUserShell = pkgs.zsh;

    users.hybridz = {
      isNormalUser = true;
      description = "Enrique Flores";
      extraGroups = [ "wheel" "input" "networkmanager" "audio" "video" ];
    };

  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    users.hybridz = import ./home-manager/home.nix;

  };

  fonts.packages = with pkgs;
    [ (nerdfonts.override { fonts = [ "FiraCode" ]; }) ];

  environment = {
    localBinInPath = true;
    pathsToLink = [ "/share/zsh" ];

  };

  nixpkgs = {
    config = {
      allowUnfree = true;

    };
  };

  programs = {

    dconf.enable = true;

    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    light = { enable = true; };

    hyprland = {

      enable = true;
      xwayland.enable = true;

    };

    zsh.enable = true;
    firefox = {
      enable = true;
      preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.fullscreen.autohide" = false;
      };
    };

  };

  services = {

    #udev = {
    #  extraRules = ''
    #    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    #  '';
    #};

    upower.enable = true;

    dbus = { enable = true; };

    flatpak.enable = true;

    batteryNotifier = {
      enable = true;
      notifyCapacity = 15;
      suspendCapacity = 7;
    };

    blueman.enable = true;

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

    # Configure keymap in X11
    xserver = {
      xkb = {
        layout = "us";
        variant = "";
      };

    };

    pipewire = {

      enable = true;

      pulse.enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };

    };

    # prevent overheating on intel CPU
    thermald.enable = true;

    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "powersave";
          turbo = "never";
        };
      };
    };
  };

  security = {

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
