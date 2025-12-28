{ pkgs, ... }:

{

  environment = {

    systemPackages =
      let
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

        # open_grep = pkgs.writeShellApplication {
        # name = "ogrep";
        # text = ''
        #     #!/bin/bash
        #
        #     # Check if pattern is provided
        #     if [ $# -eq 0 ]; then
        #         echo "Usage: $0 <pattern> [path] [editor]"
        #         echo "Example: $0 'any' . vim"
        #         exit 1
        #     fi
        #
        #     pattern="$1"
        #     path="${2:-.}"          # Default to current directory
        #     editor="${3:-${EDITOR:-vim}}"  # Use $EDITOR env var or default to vim
        #
        #     # Find files containing the pattern (-l prints only filenames)
        #     files=$(grep -rl "$pattern" "$path" 2>/dev/null)
        #
        #     if [ -z "$files" ]; then
        #         echo "No files found containing pattern: $pattern"
        #         exit 0
        #     fi
        #
        #     echo "Found pattern in the following files:"
        #     echo "$files"
        #     echo ""
        #     echo "Opening files in $editor..."
        #
        #     # Open all files in the editor
        #     $editor $files
        #
        # '';
        # };

        gcommit = pkgs.writeShellApplication {
          name = "gcommit";
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

            # check if commit message was provided as argument
            default_msg="chore: regular commit"
            if [ $# -gt 0 ]; then
            # use all remaining args as commit message
            msg="$*"
            else
            # prompt for commit message with default
            echo "Commit message (default: $default_msg):"
            read -r msg
            # use default if empty
            if [ -z "$msg" ]; then
            msg="$default_msg"
            fi
            fi

            # assemble flag
            flag=
            [ "$no_verify" = true ] && flag="--no-verify"

            # perform commit
            if git diff-index --quiet HEAD --; then
            echo "Nothing to commit."
            else
            git commit -a $flag -m "$msg"
            fi
          '';
        };

        gpush = pkgs.writeShellApplication {
          name = "gpush";
          runtimeInputs = [ gcommit ];
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

            # assemble flag
            flag=
            [ "$no_verify" = true ] && flag="--no-verify"

            # call gcommit with remaining args (commit message)
            gcommit $flag "$@"

            # pull and push
            git pull --rebase
            git push $flag
          '';
        };

        uwsm-start-logged = pkgs.writeShellApplication {
          name = "uwsm-start-logged";
          runtimeInputs = [ pkgs.uwsm ];
          text = ''
            #!/usr/bin/env bash

            LOGFILE="/tmp/uwsm-start-$(date +%Y%m%d-%H%M%S).log"

            echo "=== UWSM Start Log ===" | tee "$LOGFILE"
            echo "Date: $(date)" | tee -a "$LOGFILE"
            echo "TTY: $(tty)" | tee -a "$LOGFILE"
            echo "User: $USER" | tee -a "$LOGFILE"
            echo "Arguments: $*" | tee -a "$LOGFILE"
            echo "==================" | tee -a "$LOGFILE"
            echo "" | tee -a "$LOGFILE"

            # Run uwsm and capture all output
            exec uwsm "$@" 2>&1 | tee -a "$LOGFILE"
          '';
        };

      in
      [
        manteinance
        last_logs
        gcommit
        gpush
        uwsm-start-logged
      ];
  };
}
