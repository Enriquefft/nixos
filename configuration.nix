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
    ./security.nix
    ./virtualisation.nix

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

    # Power management
    ./modules/power/battery.nix
    ./modules/power/thermal.nix

    # Services
    ./modules/services/databases.nix
    ./modules/services/desktop.nix
    ./modules/services/display.nix
    ./modules/services/input.nix
    ./modules/services/ollama.nix

    # Programs
    ./modules/programs/hyprland.nix
    ./modules/programs/firefox.nix
    ./modules/programs/steam.nix
    ./modules/programs/zsh.nix
    ./modules/programs/development.nix

    inputs.home-manager.nixosModules.default
  ];

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "gtk2";
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
