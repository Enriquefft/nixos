{ config, pkgs, lib, ... }:

let

  fontFamily = "FiraCode Nerd Font";

in


{
  programs.kitty = {

    enable = true;
    font.name = fontFamily;
    theme = "Solarized Dark";

    settings = {
      enable_audio_bell = false;
    };

    shellIntegration.enableZshIntegration = true;

  };
}
