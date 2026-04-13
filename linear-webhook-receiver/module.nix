# linear-webhook-receiver home-manager configuration
# Receives Sentry + Linear webhooks, triages errors into Linear, triggers Claude Code
{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  receiverPkg = pkgs.buildGoModule {
    pname = "linear-webhook-receiver";
    version = "0.2.0";
    src = /etc/nixos/linear-webhook-receiver/src;
    vendorHash = null;
    doCheck = false;
    meta.mainProgram = "linear-webhook-receiver";
  };
in
{
  # Inject secrets into config.toml at activation time
  home.activation.linearWebhookReceiverConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/linear-webhook-receiver"
    $DRY_RUN_CMD sed \
      -e "s|@SENTRY_WEBHOOK_SECRET@|$(cat ${osConfig.sops.secrets."linear-webhook-receiver/sentry-webhook-secret".path})|g" \
      -e "s|@LINEAR_API_KEY@|$(cat ${osConfig.sops.secrets."linear-webhook-receiver/linear-api-key".path})|g" \
      -e "s|@LINEAR_TEAM_ID@|$(cat ${osConfig.sops.secrets."linear-webhook-receiver/linear-team-id".path})|g" \
      -e "s|@LINEAR_WEBHOOK_SECRET@|$(cat ${osConfig.sops.secrets."linear-webhook-receiver/webhook-secret".path})|g" \
      -e "s|@ZAI_API_KEY@|$(cat ${osConfig.sops.secrets."linear-webhook-receiver/zai-api-key".path})|g" \
      /etc/nixos/linear-webhook-receiver/config.toml \
      > "$HOME/.config/linear-webhook-receiver/config.toml"
    $DRY_RUN_CMD chmod 600 "$HOME/.config/linear-webhook-receiver/config.toml"
  '';

  systemd.user.services.linear-webhook-receiver = {
    Unit = {
      Description = "Sentry-Linear Bridge — triages errors + triggers Claude Code on new issues";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${receiverPkg}/bin/linear-webhook-receiver --config %h/.config/linear-webhook-receiver/config.toml";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=${pkgs.git}/bin:/run/current-system/sw/bin:/home/hybridz/.local/bin"
        "HOME=/home/hybridz"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
