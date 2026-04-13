# Webhook reverse proxy — routes all inbound webhooks from Tailscale Funnel.
#
# Single Caddy instance on :9000 routes by path:
#   /webhook/sentry*  →  sentry-linear-bridge (Go, port 8765)
#   /webhook/linear*  →  sentry-linear-bridge (Go, port 8765)
#   /webhook*         →  kapso-whatsapp-bridge (port 18790)
#
# Tailscale Funnel is configured separately (one-time, persists across reboots):
#   tailscale serve --bg http://localhost:9000
#   tailscale funnel --bg 443
#
# This replaces kapso's delivery.mode = "tailscale" (which owned port 443
# exclusively), allowing multiple services to share a single Funnel endpoint.
{ ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts.":9000" = {
      extraConfig = ''
        handle /webhook/sentry* {
          reverse_proxy localhost:8765
        }
        handle /webhook/linear* {
          reverse_proxy localhost:8765
        }
        handle /webhook* {
          reverse_proxy localhost:18790
        }
      '';
    };
  };
}
