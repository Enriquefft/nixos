{ ... }:
{
  sops.secrets."linear-webhook-receiver/linear-api-key" = {
    sopsFile = ../../secrets/linear-webhook-receiver.yaml;
    owner = "hybridz";
  };
  sops.secrets."linear-webhook-receiver/linear-team-id" = {
    sopsFile = ../../secrets/linear-webhook-receiver.yaml;
    owner = "hybridz";
  };
  sops.secrets."linear-webhook-receiver/sentry-webhook-secret" = {
    sopsFile = ../../secrets/linear-webhook-receiver.yaml;
    owner = "hybridz";
  };
  sops.secrets."linear-webhook-receiver/webhook-secret" = {
    sopsFile = ../../secrets/linear-webhook-receiver.yaml;
    owner = "hybridz";
  };
  sops.secrets."linear-webhook-receiver/zai-api-key" = {
    sopsFile = ../../secrets/linear-webhook-receiver.yaml;
    owner = "hybridz";
  };
}
