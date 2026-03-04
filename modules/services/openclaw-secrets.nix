{ config, ... }:

{
  sops.secrets = {
    "openclaw/zai-api-key" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/kapso-api-key" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/gateway-token" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/kapso-phone-number-id" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/kapso-webhook-secret" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/kapso-webhook-verify-token" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/gog-keyring-password" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
    "openclaw/brave-api-key" = {
      sopsFile = ../../secrets/openclaw.yaml;
      owner = "hybridz";
    };
  };

  # Render a single env file from all secrets for the systemd service
  sops.templates."openclaw.env" = {
    content = ''
      ZAI_API_KEY=${config.sops.placeholder."openclaw/zai-api-key"}
      KAPSO_API_KEY=${config.sops.placeholder."openclaw/kapso-api-key"}
      OPENCLAW_TOKEN=${config.sops.placeholder."openclaw/gateway-token"}
      KAPSO_PHONE_NUMBER_ID=${config.sops.placeholder."openclaw/kapso-phone-number-id"}
      GOG_KEYRING_PASSWORD=${config.sops.placeholder."openclaw/gog-keyring-password"}
      BRAVE_API_KEY=${config.sops.placeholder."openclaw/brave-api-key"}
    '';
    owner = "hybridz";
  };
}
