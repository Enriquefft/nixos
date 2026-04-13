# User Configuration
# Main user account and permissions
{ pkgs, ... }:

let
  constants = import ../../shared/constants.nix;
in {
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      plugdev = { };
    };

    users.${constants.user.name} = {
      isNormalUser = true;
      description = constants.user.description;
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

  # Auto-login on tty1 (skip username/password prompt)
  # Hyprland starts automatically via zsh loginExtra
  services.getty.autologinUser = constants.user.name;

  systemd.tmpfiles.rules = [
    # Grant user write access to /etc/nixos for flake-based configuration management
    # Format: A+ (add ACL), path, -, -, -, -, user:permissions
    "A+       /etc/nixos -    -    -     -           u:${constants.user.name}:rwx"
  ];
}
