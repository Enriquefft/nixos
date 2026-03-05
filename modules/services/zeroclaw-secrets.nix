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
    '';
    owner = "hybridz";
  };

  # Render config.toml via sops template so brave_api_key can be substituted at activation time
  sops.templates."zeroclaw-config" = {
    content = ''
      # ZeroClaw configuration — managed by NixOS, do not edit manually
      default_provider = "zai-coding"
      default_model = "glm-5"
      default_temperature = 0.7

      [model_providers.zai]
      base_url = "https://api.z.ai/api/paas/v4"
      wire_api = "chat_completions"

      [model_providers.zai-coding]
      base_url = "https://api.z.ai/api/coding/paas/v4"
      wire_api = "chat_completions"

      [identity]
      format = "openclaw"

      [gateway]
      port = 42617
      host = "127.0.0.1"
      require_pairing = false

      [browser]
      enabled = true
      browser_open = "chrome"
      native_chrome_path = "/run/current-system/sw/bin/kiro-browser"

      [web_search]
      enabled = true
      provider = "brave"
      brave_api_key = "${config.sops.placeholder."zeroclaw/brave-api-key"}"

      [channels_config]
      cli = true

      [autonomy]
      level = "supervised"
      workspace_only = false
      max_actions_per_hour = 9999
      max_cost_per_day_cents = 500
      allowed_roots = ["/etc/nixos/", "~/Projects/", "~/.zeroclaw/documents/"]
      allowed_commands = [
        "git", "nix", "nixos-rebuild", "systemctl", "journalctl",
        "zeroclaw", "gpush", "gcommit", "gh", "cargo",
        "node", "bun", "npm", "python3", "bash", "sh",
        "ls", "cat", "grep", "find", "cp", "mv", "rm",
        "mkdir", "chmod", "chown", "curl", "wget", "jq",
        "direnv", "sudo"
      ]
      forbidden_paths = [
        "/root", "/usr", "/bin", "/sbin", "/lib", "/opt",
        "/boot", "/dev", "/proc", "/sys", "/var", "/tmp",
        "~/.ssh", "~/.gnupg", "~/.aws", "~/.config"
      ]
      non_cli_excluded_tools = [
        "shell",
        "file_write",
        "file_edit",
        "git_operations",
        "browser",
        "browser_open",
        "http_request",
        "schedule",
        "memory_store",
        "memory_forget",
        "proxy_config",
        "model_routing_config",
        "pushover",
        "composio",
        "delegate",
        "screenshot",
        "image_info"
      ]

      [memory]
      backend = "sqlite"
      auto_save = true

      [observability]
      backend = "none"
      runtime_trace_mode = "rolling"
      runtime_trace_max_entries = 200

      [agent]
      max_tool_iterations = 40
      max_history_messages = 100

      [agents_ipc]
      enabled = true
      db_path = "~/.zeroclaw/agents.db"
      staleness_secs = 300
    '';
    owner = "hybridz";
  };
}
