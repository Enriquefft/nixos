{ inputs, pkgs, config, ... }:

{
  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = "on";
      splash = false;

      # Preload wallpaper
      preload = [ "${config.home.homeDirectory}/Pictures/walppaper.png" ];

      # Set wallpaper for all monitors
      wallpaper = [ ",${config.home.homeDirectory}/Pictures/walppaper.png" ];
    };
  };
}
