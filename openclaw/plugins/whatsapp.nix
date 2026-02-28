{ kapsoPackages, kapso-whatsapp-plugin }:
{
  home.packages = [ kapsoPackages.cli ];

  home.file.".openclaw/workspace/skills/whatsapp" = {
    source = "${kapso-whatsapp-plugin}/skills/whatsapp";
    recursive = true;
  };

  systemd.user.services.kapso-whatsapp-poller = {
    Unit = {
      Description = "Kapso WhatsApp Poller";
      After = [ "openclaw-gateway.service" ];
      Requires = [ "openclaw-gateway.service" ];
    };
    Service = {
      ExecStart = "${kapsoPackages.poller}/bin/kapso-whatsapp-poller";
      Restart = "on-failure";
      RestartSec = 10;
      # EnvironmentFile: injected by the NixOS config (machine-specific)
    };
    Install.WantedBy = [ "default.target" ];
  };
}
