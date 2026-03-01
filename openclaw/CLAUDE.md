# OpenClaw Agent Configuration

This directory is the personal OpenClaw agent configuration sub-flake.
Agents working on OpenClaw settings can `cd /etc/nixos/openclaw/` and work here
without needing NixOS context.

## Key Files

| File | Purpose |
|------|---------|
| `module.nix` | Gateway config, model providers (ZAI), agent defaults |
| `documents/` | Agent identity: AGENTS.md, SOUL.md, TOOLS.md |
| `plugins/whatsapp.nix` | Kapso WhatsApp poller wiring |
| `flake.nix` | Sub-flake inputs (nixpkgs, nix-openclaw, kapso-whatsapp-plugin) |

## Secrets

Secrets are NOT here. They are injected at runtime from `/run/secrets/rendered/openclaw.env`
by the NixOS machine config (`home-manager/home.nix` + `modules/services/openclaw-secrets.nix`).

Environment variables available at runtime:
- `OPENCLAW_TOKEN` — gateway auth token
- `ZAI_API_KEY` — Z.AI API key
- `KAPSO_API_KEY` — Kapso API key
- `KAPSO_PHONE_NUMBER_ID` — WhatsApp phone number ID

## Testing

```bash
# Validate sub-flake syntax
nix flake check

# Full system build (from /etc/nixos)
nixos-rebuild test --flake /etc/nixos#nixos
# or simply
up

# Check services after rebuild
systemctl --user status openclaw-gateway kapso-whatsapp-poller
```

## Document-only changes

Editing files in `documents/` (AGENTS.md, SOUL.md, TOOLS.md) only requires a
`nixos-rebuild test` to activate — no Go rebuild is triggered.
