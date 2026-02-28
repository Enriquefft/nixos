{
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  programs.openclaw = {
    enable = true;

    documents = ./openclaw-documents;

    config = {
      gateway = {
        mode = "local";
        auth = {
          # Substituted at runtime from EnvironmentFile
          token = "\${OPENCLAW_TOKEN}";
        };
      };

      # Z.AI GLM via OpenAI-compatible API
      models.providers.zai = {
        baseUrl = "https://api.z.ai/api/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [
          { id = "glm-5"; name = "GLM 5"; }
        ];
      };

      # Z.AI Coding endpoint (dedicated for coding tasks)
      models.providers.zai-coding = {
        baseUrl = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [
          { id = "glm-5"; name = "GLM 5 Coding"; }
        ];
      };

      agents.defaults.model = {
        primary = "zai-coding/glm-5";
        fallbacks = [ "zai/glm-5" ];
      };

    };

    systemd = {
      enable = true;
      unitName = "openclaw-gateway";
    };

    bundledPlugins = { };
    customPlugins = [ ];
  };

  # The nix-openclaw homeFile doesn't set force = true, causing conflicts when the file
  # pre-exists as a regular file. This overrides it to allow home-manager to take ownership.
  home.file.".openclaw/openclaw.json".force = true;

  # Inject secrets via EnvironmentFile (rendered by sops-nix at /run/secrets/rendered/openclaw.env)
  # NOTE: Kapso MCP will be configured post-install via `openclaw config` CLI
  systemd.user.services.openclaw-gateway = {
    Service.EnvironmentFile = [ "/run/secrets/rendered/openclaw.env" ];
    Install.WantedBy = [ "default.target" ];
  };
}
