{ config, pkgs, ... }:

{
  # Cloudflare Tunnel for receiving Kapso WhatsApp webhooks.
  # Run `cloudflared tunnel login` and `cloudflared tunnel create kapso-webhook`
  # first, then encrypt credentials with sops.

  sops.secrets."cloudflared/tunnel-credentials" = {
    sopsFile = ../../secrets/cloudflared.yaml;
    owner = "cloudflared";
    group = "cloudflared";
  };

  services.cloudflared = {
    enable = true;
    tunnels."kapso-webhook" = {
      credentialsFile = config.sops.secrets."cloudflared/tunnel-credentials".path;
      default = "http_status:404";
      ingress = {
        # Replace TUNNEL_UUID with actual UUID after `cloudflared tunnel create`.
        # The hostname will be <UUID>.cfargotunnel.com
        "kapso-webhook.cfargotunnel.com" = {
          service = "http://localhost:18790";
        };
      };
    };
  };

  environment.systemPackages = [ pkgs.cloudflared ];
}
