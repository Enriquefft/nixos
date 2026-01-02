# Network Configuration
# NetworkManager with firewall and Google DNS
{ ... }:

let
  constants = import ../../shared/constants.nix;
in {
  networking = {
    hostName = constants.hostname;
    networkmanager.enable = true;
    firewall.enable = true;

    # Open ports in the firewall
    firewall.allowedTCPPorts = [
      80
      443
    ];
    firewall.allowedUDPPorts = [
      80
      443
    ];

    nameservers = [
      constants.dns.primary
      constants.dns.secondary
    ];
  };
}
