{ config, ... }:

{
  sops.secrets = {
    "zeroclaw/zai-api-key" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/kapso-api-key" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/gateway-token" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/kapso-phone-number-id" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/kapso-webhook-secret" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/kapso-webhook-verify-token" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/gog-keyring-password" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/brave-api-key" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
    "zeroclaw/spacemail-password" = {
      sopsFile = ../../secrets/zeroclaw.yaml;
      owner = "hybridz";
    };
};

  # Render a single env file from all secrets for the systemd service
  sops.templates."zeroclaw.env" = {
    content = ''
      ZEROCLAW_API_KEY=${config.sops.placeholder."zeroclaw/zai-api-key"}
      ZAI_API_KEY=${config.sops.placeholder."zeroclaw/zai-api-key"}
      KAPSO_API_KEY=${config.sops.placeholder."zeroclaw/kapso-api-key"}
      ZEROCLAW_TOKEN=${config.sops.placeholder."zeroclaw/gateway-token"}
      KAPSO_PHONE_NUMBER_ID=${config.sops.placeholder."zeroclaw/kapso-phone-number-id"}
      GOG_KEYRING_PASSWORD=${config.sops.placeholder."zeroclaw/gog-keyring-password"}
      BRAVE_API_KEY=${config.sops.placeholder."zeroclaw/brave-api-key"}
      SPACEMAIL_PASSWORD=${config.sops.placeholder."zeroclaw/spacemail-password"}
    '';
    owner = "hybridz";
  };
}
