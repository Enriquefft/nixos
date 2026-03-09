# Yap - Hold-to-Talk Voice Dictation
# https://github.com/hybridz/yap
{ config, ... }:

let
  constants = import ../../shared/constants.nix;
in
{
  services.yap = {
    enable = true;
    user = constants.user.name;
  };
}
