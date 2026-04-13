# OpenScreen — desktop screen recorder with built-in editor
{ pkgs, inputs, ... }:

{
  programs.openscreen = {
    enable = true;
    package = inputs.openscreen.packages.${pkgs.stdenv.hostPlatform.system}.openscreen;
  };
}
