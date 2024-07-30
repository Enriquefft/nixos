{ pkgs, ... }: {
  home.pointerCursor = {
    x11.enable = true;
    name = "Adwaita";
# in nixpkgs unstable
    #package = pkgs.adwaita-icon-theme;
    package = pkgs.gnome.adwaita-icon-theme;
    size = 32;
  };
}
