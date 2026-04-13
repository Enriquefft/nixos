# Network Configuration
# NetworkManager with firewall and Google DNS
{ ... }:

let
  constants = import ../../shared/constants.nix;
in {
  networking = {
    hostName = constants.hostname;
    networkmanager.enable = true;
    firewall = {
      enable = true;

      # Trust Tailscale interface — all traffic between your devices is allowed
      trustedInterfaces = [ "tailscale0" ];

      # Public-facing ports (local network only — Tailscale handles remote access)
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ 80 443 ];
    };

    nameservers = [
      constants.dns.primary
      constants.dns.secondary
    ];
  };
}
