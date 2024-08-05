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

      last_logs = pkgs.writeShellApplication {
        name = "last_logs";
        text = ''
          journalctl --boot=-1
        '';
      };

    in [
      manteinance
      last_logs
    ];
  };
}
