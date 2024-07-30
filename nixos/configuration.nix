# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ inputs, config, pkgs, ... }:

{

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    #./suspend.nix
    ./applications.nix
    ./nix.nix
    inputs.home-manager.nixosModules.default
  ];

  # use the systemd-boot EFI boot loader.
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
 
    # kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;

    # plymouth.enable = true;

  };

#  xdg = {
#    autostart.enable = true;
#    portal = {
#
#      extraPortals = [
#        pkgs.xdg-desktop-portal-gtk
#
#      ];
#
#      enable = true;
#    };
#  };
#
  networking = {

    hostName = "nixos";
    networkmanager.enable = true;

  };

  # Set your time zone.
  time.timeZone = "America/Lima";
  location = {
    latitude = -12.11;
    longitude = -76.98;

  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "es_PE.UTF-8/UTF-8" ];
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

 # qt = {
 #   enable = true;
 #   platformTheme = "gtk2";
 #   style = "gtk2";
 # };

  hardware = {

pulseaudio.enable = false;
    bluetooth = {

      enable = true;
      powerOnBoot = false;
    };

    cpu.intel.updateMicrocode = true;

    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    #graphics = {
      #enable = true;
      #enable32Bit = true;
#
    #};
#
    #nvidia = {
      #modesetting.enable = true;
#
      #powerManagement = {
#
        #enable = false;
#
        #finegrained = true;
      #};
#
      #prime = {
#
        #intelBusId = "PCI:0:2:0";
        #nvidiaBusId = "PCI:1:0:0";
#
        #offload = {
#
          #enable = true;
          #enableOffloadCmd = true;
        #};
#
      #};
#
      #open = false;
#
      #nvidiaSettings = true;
#
      #package = config.boot.kernelPackages.nvidiaPackages.stable;
#
    #};

  };

  powerManagement.enable = true;

  users = {

    defaultUserShell = pkgs.zsh;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.hybridz = {
      isNormalUser = true;
description="Enrique Flores";
      extraGroups = [ "wheel" "input" "networkmanager" "audio" "video" ];
    };

  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    users.hybridz = import ./home-manager/home.nix;

  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  fonts.packages = with pkgs;
    [

      (nerdfonts.override { fonts = [ "FiraCode" ]; })

    ];

  environment = {

    localBinInPath = true;

    pathsToLink = [ "/share/zsh" ];

  };

  nixpkgs = {

    config = {
      allowUnfree = true;

    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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
     # preferences = { "widget.use-xdg-desktop-portal.file-picker" = 1; };
    };
    waybar = {
      enable = true;

    };

  };

  # List services that you want to enable:
  services = {

    #udev = {
    #  extraRules = ''
    #    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    #  '';
    #};

    #upower.enable = true;

    dbus = { enable = true; };

    flatpak.enable = true;

    #batteryNotifier = {
    #  enable = true;
    #  notifyCapacity = 15;
    #  suspendCapacity = 4;
    #};

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

    # Configure keymap in X11

    # Enable CUPS to print documents.
    printing.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).

    # Enable the OpenSSH daemon.
    openssh.enable = true;

    libinput.enable = true;
    xserver = {
xkb = {
layout= "us";

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

 #   auto-cpufreq = {
 #     enable = true;
 #     settings = {
 #       battery = {
 #         governor = "powersave";
 #         turbo = "never";
 #       };
#        charger = {
#          governor = "powersave";
#          turbo = "never";
#        };
#      };
#    };
};


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

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

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

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
