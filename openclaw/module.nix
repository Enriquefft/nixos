{ nix-openclaw, kapso-whatsapp-plugin }:
{ pkgs, ... }:
let
  kapsoPackages = kapso-whatsapp-plugin.packages.${pkgs.system};
in
{
  imports = [
    nix-openclaw.homeManagerModules.openclaw
    (import ./plugins/whatsapp.nix { inherit kapsoPackages kapso-whatsapp-plugin; })
  ];

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
