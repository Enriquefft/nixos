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
  };

  # Render a single env file from all secrets for the systemd service
  sops.templates."openclaw.env" = {
    content = ''
      ZAI_API_KEY=${config.sops.placeholder."openclaw/zai-api-key"}
      KAPSO_API_KEY=${config.sops.placeholder."openclaw/kapso-api-key"}
      OPENCLAW_TOKEN=${config.sops.placeholder."openclaw/gateway-token"}
      KAPSO_PHONE_NUMBER_ID=${config.sops.placeholder."openclaw/kapso-phone-number-id"}
    '';
    owner = "hybridz";
  };
}
