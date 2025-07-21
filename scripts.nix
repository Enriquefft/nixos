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

          # parse options with getopt
          OPTS=$(getopt -o "" -l no-verify -- "$@") || exit 1
          eval set -- "$OPTS"

          no_verify=false
          while true; do
          case "$1" in
          --no-verify)
          no_verify=true
          shift
          ;;
          --)
          shift
          break
          ;;
          *)
          shift
          ;;
          esac
          done

          # commit message
          if [ $# -gt 0 ]; then
          msg="$*"
          else
          msg="chore: regular commit"
          fi

          # assemble flag
          flag=
          [ "$no_verify" = true ] && flag="--no-verify"

          # perform commit & push
          if git diff-index --quiet HEAD --; then
          echo "Nothing to commit."
          else
          git commit -a $flag -m "$msg"
          fi
          git pull --rebase
          git push $flag
        '';
      };

    in [ manteinance last_logs gpush ];
  };
}
