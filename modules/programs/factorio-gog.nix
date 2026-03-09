# Factorio v2.0.73 (GOG) wrapper
#
# Installation:
#   wget 'https://dn721601.ca.archive.org/0/items/factorio-v-1.1.101-linux-gog-v-70357-gui/Factorio%20%2B%20DLC-Bonus%20%5BLinux%2C%20GOG%5D/factorio_2_0_73_88209.sh'
#   chmod +x factorio_2_0_73_88209.sh
#   ./factorio_2_0_73_88209.sh  # Extract to ~/Games/Factorio/
{ pkgs, lib, ... }:

let
  factorioPath = "/home/hybridz/Games/Factorio/data/noarch/game";

  runtimeLibs = with pkgs; [
    libGL
    libGLU
    libx11
    libxcursor
    libxrandr
    libxi
    libxinerama
    alsa-lib
  ];

  factorio-wrapper = pkgs.writeShellScriptBin "factorio" ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath runtimeLibs}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ${factorioPath}/bin/x64/factorio "$@"
  '';

  factorio-desktop = pkgs.makeDesktopItem {
    name = "factorio";
    desktopName = "Factorio";
    comment = "Factorio v2.0.73 (GOG)";
    exec = "factorio";
    icon = "${factorioPath}/../support/icon.png";
    categories = [ "Game" ];
  };
in
{
  environment.systemPackages = [
    factorio-wrapper
    factorio-desktop
  ];
}
