{ pkgs, ... }:

{

  environment = {

    systemPackages = let
      manteinance = pkgs.writeShellApplication {
        name = "mant";
        text = ''
          journalctl -b -p 3
        '';
      };
    in [
      manteinance

    ];
  };
}
