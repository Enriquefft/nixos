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

          # commit message
          if [ $# -gt 0 ]; then
            msg="$*"
          else
            msg="chore: regular commit"
          fi

          # if no changes, exit zero and continue script
          if git diff-index --quiet HEAD --; then
            echo "Nothing to commit."
          else
            git commit -a -m "$msg"
          fi
          git push


        '';
      };

    in [ manteinance last_logs gpush ];
  };
}
