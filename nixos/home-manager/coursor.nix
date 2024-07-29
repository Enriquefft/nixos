{ pkgs, ... }: {
  home.pointerCursor = {
    x11.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 32;
  };
}
