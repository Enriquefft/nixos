# Desktop Services
# Essential desktop environment services
{ ... }:

{
  services = {
    dbus.enable = true;
    flatpak.enable = true;
    blueman.enable = true;
    printing.enable = true;
    openssh.enable = true;
    envfs.enable = true;
    upower.enable = true;
  };
}
