# Security Configuration
# Polkit, RTKit, PAM, sudo, and doas
{ ... }:

let
  constants = import ./shared/constants.nix;
in {
  security = {
    polkit.enable = true;
    rtkit.enable = true;

    pam.services.login.enableGnomeKeyring = true;

    # Enabled to be used with sudoedit (svim alias)
    sudo.enable = true;

    doas = {
      enable = true;
      extraRules = [
        {
          users = [ constants.user.name ];
          keepEnv = true;
          persist = true;
        }
      ];
    };
  };
}
