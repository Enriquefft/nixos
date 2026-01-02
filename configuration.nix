# Options: https://search.nixos.org/options
flake-overlays:
{
  config,
  inputs,
  pkgs,
  ...
}:

let
  constants = import ./shared/constants.nix;
in {

  imports = [
    ./hardware-configuration.nix
    ./applications.nix
    ./scripts.nix
    ./suspend.nix
    ./hyprland-battery-effects.nix

    # System modules
    ./modules/system/boot.nix
    ./modules/system/networking.nix
    ./modules/system/locale.nix
    ./modules/system/users.nix
    ./modules/system/nix.nix

    # Hardware modules
    ./modules/hardware/graphics.nix
    ./modules/hardware/nvidia-disable.nix
    ./modules/hardware/bluetooth.nix
    ./modules/hardware/audio.nix
    ./modules/hardware/peripherals.nix

    inputs.home-manager.nixosModules.default
  ];

  qt = {
    enable = true;
    # TODO: rice xd
    # platformTheme = "gtk2";
    # style = "gtk2";
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    useGlobalPkgs = true;
    users.${constants.user.name} = import ./home-manager/home.nix;
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
