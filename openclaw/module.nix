{ nix-openclaw, kapso-whatsapp-plugin }:
{ pkgs, ... }:
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
    package = kapsoPackages.poller;
    cliPackage = kapsoPackages.cli;

    security = {
      mode = "allowlist";
      roles = { owner = [ "+51926689401" ]; };
      sessionIsolation = false;
    };
  };

  # Skill symlink (not managed by the kapso HM module)
  home.file.".openclaw/workspace/skills/whatsapp" = {
    source = "${kapso-whatsapp-plugin}/skills/whatsapp";
    recursive = true;
  };

  programs.openclaw = {
    enable = true;
    documents = ./documents;
    config = {
      gateway.mode = "local";
      gateway.auth.token = "\${OPENCLAW_TOKEN}";
      models.providers.zai = {
        baseUrl = "https://api.z.ai/api/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [ { id = "glm-5"; name = "GLM 5"; } ];
      };
      models.providers.zai-coding = {
        baseUrl = "https://api.z.ai/api/coding/paas/v4";
        apiKey = "\${ZAI_API_KEY}";
        api = "openai-completions";
        models = [ { id = "glm-5"; name = "GLM 5 Coding"; } ];
      };
      agents.defaults.model = {
        primary = "zai-coding/glm-5";
        fallbacks = [ "zai/glm-5" ];
      };
    };
    systemd = { enable = true; unitName = "openclaw-gateway"; };
    bundledPlugins = { };
    customPlugins = [ ];
  };

  # nix-openclaw workaround: pre-existing file causes HM conflict without force
  home.file.".openclaw/openclaw.json".force = true;

  # Gateway must start on login (nix-openclaw doesn't set WantedBy itself)
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];
}
