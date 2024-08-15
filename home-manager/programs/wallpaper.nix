{ inputs, pkgs, config, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = true;
    };
  };
}
