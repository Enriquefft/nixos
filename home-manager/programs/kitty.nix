{ config, pkgs, lib, ... }:

let

  fontFamily = "FiraCode Nerd Font";

in {
  programs.kitty = {

    enable = true;
    font.name = fontFamily;
    themeFile = "Solarized_Dark";

    settings = { enable_audio_bell = false; };

    shellIntegration.enableZshIntegration = true;

  };
}
