{ inputs, pkgs, config, ... }:

let
  wallpaper = pkgs.fetchurl {
    url = "https://i.redd.it/mvev8aelh7zc1.png";
    hash = "sha256-lJjIq+3140a5OkNy/FAEOCoCcvQqOi73GWJGwR2zT9w";
  };
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = true;
      preload = [ (builtins.toString wallpaper) ];

      wallpaper = [ ",${builtins.toString wallpaper}" ];
    };
  };
}
