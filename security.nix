# Security Configuration
# Polkit, RTKit, PAM, sudo, and doas
{ ... }:

let
  constants = import ./shared/constants.nix;
in {
  security = {
    polkit.enable = true;
    rtkit.enable = true;

    # gnome-keyring unlocked via Hyprland exec-once (PAM can't unlock with auto-login)
    # pam.services.login.enableGnomeKeyring = true;

    # Enabled to be used with sudoedit (svim alias)
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults pwfeedback
      '';
      execWheelOnly = true;
    };

    doas = {
      enable = true;
      extraRules = [
        # Passwordless commands (whitelist for autonomous execution)
        {
          users = [ constants.user.name ];
          cmd = "/run/current-system/sw/bin/nixos-rebuild";
          noPass = true;
        }
        {
          users = [ constants.user.name ];
          cmd = "/run/current-system/sw/bin/systemctl";
          noPass = true;
        }
        {
          users = [ constants.user.name ];
          cmd = "/run/current-system/sw/bin/nix-collect-garbage";
          noPass = true;
        }
        {
          users = [ constants.user.name ];
          cmd = "/run/current-system/sw/bin/journalctl";
          noPass = true;
        }
        {
          users = [ constants.user.name ];
          cmd = "/run/current-system/sw/bin/tlp";
          noPass = true;
        }
        # Everything else with password persist
        {
          users = [ constants.user.name ];
          keepEnv = true;
          persist = true;
        }
      ];
    };
  };

  # Passwordless commands for sudo (whitelist for autonomous execution)
  security.sudo.extraRules = [
    {
      users = [ constants.user.name ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nix-collect-garbage"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/journalctl"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/tlp"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
