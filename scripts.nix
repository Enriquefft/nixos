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

      gpush = pkgs.writeShellApplication {
        name = "gpush";
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          if [ $# -gt 0 ]; then
            msg="$*"
          else
            msg="chore: regular commit"
          fi

          git commit -a -m "$msg" && git push
        '';
      };

    in [ manteinance last_logs gpush ];
  };
}
