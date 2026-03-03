{ nix-openclaw, kapso-whatsapp-plugin }:
{ pkgs, config, ... }:
let
  kapsoPackages = kapso-whatsapp-plugin.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    nix-openclaw.homeManagerModules.openclaw
    kapso-whatsapp-plugin.homeManagerModules.default
  ];

  # Kapso WhatsApp bridge (module manages CLI, systemd service, config.toml)
  services.kapso-whatsapp = {
    enable = true;
    package = kapsoPackages.bridge;
    cliPackage = kapsoPackages.cli;

    delivery.mode = "tailscale";

    security = {
      mode = "allowlist";
      roles = {
        owner = [ "+51926689401" ];
      };
      sessionIsolation = false;
      # Group support - prefix required to trigger bot in groups
      # groupPrefix = "!claw";
      # groupIds = [ ]; # Add group IDs here when known (format: 120363xxx@g.us)
    };

    transcribe = {
      provider = "local";
      binaryPath = "/run/current-system/sw/bin/whisper-cli";
      modelPath = "/home/hybridz/ggml-base.bin";
      language = "es";
    };
  };

  # Skill symlinks (mkOutOfStoreSymlink = live edits, no rebuild needed)
  home.file.".openclaw/workspace/skills/whatsapp".source =
    config.lib.file.mkOutOfStoreSymlink "/home/hybridz/Projects/openclaw-kapso-whatsapp/skills/whatsapp";

  programs.openclaw = {
    enable = true;
    config = {
      gateway.mode = "local";
      gateway.auth.token = "\${OPENCLAW_TOKEN}";
      models.providers.zai = {
        baseUrl = "https://api.z.ai/api/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [
          {
            id = "glm-5";
            name = "GLM 5";
          }
          {
            id = "glm-4.7";
            name = "GLM 4.7";
          }
          {
            id = "glm-4.7-flash";
            name = "GLM 4.7 Flash";
          }
        ];
      };
      models.providers.zai-coding = {
        baseUrl = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [
          {
            id = "glm-5";
            name = "GLM 5 Coding";
          }
          {
            id = "glm-4.7";
            name = "GLM 4.7 Coding";
          }
        ];
      };
      agents.defaults.model = {
        primary = "zai-coding/glm-5";
        fallbacks = [
          "zai/glm-5"
          "zai-coding/glm-4.7"
        ];
      };
      agents.defaults.heartbeat = {
        model = "zai/glm-4.7-flash";
      };
      agents.defaults.subagents = {
        model = "zai-coding/glm-4.7";
      };
      agents.defaults.models = {
        "zai-coding/glm-5" = {
          alias = "glm5";
        };
        "zai-coding/glm-4.7" = {
          alias = "4.7";
        };
        "zai/glm-4.7-flash" = {
          alias = "flash";
        };
      };
      # Browser config - use kiro-browser for dedicated workspace 8
      browser = {
        executablePath = "/run/current-system/sw/bin/kiro-browser";
      };
    };
    systemd = {
      enable = true;
      unitName = "openclaw-gateway";
    };
    bundledPlugins = { };
    customPlugins = [ ];
  };

  # nix-openclaw workaround: pre-existing file causes HM conflict without force
  home.file.".openclaw/openclaw.json".force = true;

  # Gateway must start on login (nix-openclaw doesn't set WantedBy itself)
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];
}
