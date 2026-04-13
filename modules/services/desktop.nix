# Desktop Services
# Essential desktop environment services
{ ... }:

{
  services = {
    dbus.enable = true;
    flatpak.enable = true;
    blueman.enable = true;
    printing.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };
    };
    envfs.enable = true;
    upower.enable = true;
  };
}
