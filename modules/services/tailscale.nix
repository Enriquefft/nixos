{ ... }:

let
  constants = import ../../shared/constants.nix;
in {
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=${constants.user.name}" ];
  };
}
