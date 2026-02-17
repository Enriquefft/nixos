# Virtualisation Configuration
# Docker container runtime
{ lib, ... }:

{
  virtualisation.docker.enable = true;

  # Don't auto-start Docker - use 'sudo systemctl start docker' when needed
  systemd.services.docker.wantedBy = lib.mkForce [];
}
