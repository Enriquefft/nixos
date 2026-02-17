{ pkgs, config, ... }:

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
                        OPTS=$(getopt -o "" -l no-verify,ai -- "$@") || exit 1
                        eval set -- "$OPTS"

                        no_verify=false
                        use_ai=false
                        while true; do
                        case "$1" in
                        --no-verify)
                        no_verify=true
                        shift
                        ;;
                        --ai)
                        use_ai=true
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

                        if [ "$use_ai" = true ]; then
                            if git diff-index --quiet HEAD --; then
                                echo "Nothing to commit."
                                exit 0
                            fi

                            DIFF=$(git diff HEAD)

                            PROMPT="You are a commit assistant.
            Below is a git diff of the current changes.
            Goal: Create a bash script to commit these changes in an orderly manner.
            Requirements:
            1. Group changes into logical commits.
            2. Use Conventional Commits (type: subject).
            3. Use 'git add <file>' then 'git commit -m \"<msg>\"'. ALWAYS quote the message.
            4. Do not push.
            5. Output ONLY the bash commands. No markdown code blocks. No explanations.
            6. The output will be directly executed as a bash script. Each command on its own line.

            Changes:
            $DIFF"

                            PLAN=""

                            # Try Claude (Haiku)
                            if command -v claude &> /dev/null; then
                                echo "🤖 asking Claude (haiku)..."
                                PLAN=$(claude --model claude-3-haiku-20240307 -p "$PROMPT" 2>/dev/null || true)
                            fi

                            # Fallback to Gemini (Flash)
                            if [ -z "''${PLAN:-}" ] && command -v gemini &> /dev/null; then
                                echo "🤖 Claude failed/missing. Asking Gemini (flash)..."
                                PLAN=$(gemini --model gemini-1.5-flash -o text -p "$PROMPT" 2>/dev/null || true)
                            fi

                            # Fallback to Copilot
                            if [ -z "''${PLAN:-}" ] && command -v gh &> /dev/null; then
                                if gh extension list 2>/dev/null | grep -q "copilot"; then
                                    echo "🤖 Gemini failed/missing. Asking Copilot..."
                                    PLAN=$(gh copilot suggest -t shell "$PROMPT" 2>/dev/null || true)
                                fi
                            fi

                            if [ -z "''${PLAN:-}" ]; then
                                echo "❌ All AI assistants failed or returned empty."
                                exit 1
                            fi

                            # Clean the output: strip code fences, keep only git commands
                            PLAN=$(echo "$PLAN" | sed 's/^```bash//g' | sed 's/^```//g' | sed 's/```$//g')
                            PLAN=$(echo "$PLAN" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                            PLAN=$(echo "$PLAN" | grep -E '^git (add|commit|rm) ')

                            if [ -z "$PLAN" ]; then
                                 echo "❌ AI returned empty plan after cleaning."
                                 exit 1
                            fi

                            echo ""
                            echo "📋 Proposed Commit Plan:"
                            echo "─────────────────────────────────────────"

                            commit_num=0
                            while IFS= read -r line; do
                                # Skip empty lines
                                [[ -z "$line" ]] && continue
                                if [[ "$line" == git\ commit* ]]; then
                                    commit_num=$((commit_num + 1))
                                    # Extract message from -m "..." or -m '...'
                                    msg=$(echo "$line" | sed -n 's/.*-m ["\x27]\?\([^"\x27]*\)["\x27]\?$/\1/p')
                                    [[ -z "$msg" ]] && msg="''${line##*-m }"
                                    echo "  📝 Commit $commit_num: $msg"
                                elif [[ "$line" == git\ add* ]]; then
                                    files="''${line#git add }"
                                    echo "     + $files"
                                fi
                            done <<< "$PLAN"

                            echo "─────────────────────────────────────────"
                            echo "  Total: $commit_num commit(s)"
                            echo ""

                            read -p "Execute this plan? (y/N) " -r
                            if [[ $REPLY =~ ^[Yy]$ ]]; then
                                echo ""
                                echo "🚀 Executing..."
                                echo ""
                                eval "$PLAN"
                                echo ""
                                echo "✅ All $commit_num commit(s) applied."
                            else
                                echo "🚫 Aborted."
                                exit 1
                            fi
                            # Return to allow gpush to continue with pull/push
                        fi

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
            OPTS=$(getopt -o "" -l no-verify,ai -- "$@") || exit 1
            eval set -- "$OPTS"

            no_verify=false
            use_ai=false
            while true; do
            case "$1" in
            --no-verify)
            no_verify=true
            shift
            ;;
            --ai)
            use_ai=true
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

            # assemble flags
            flag=
            [ "$no_verify" = true ] && flag="--no-verify"
            ai_flag=
            [ "$use_ai" = true ] && ai_flag="--ai"

            # call gcommit with flags and remaining args (commit message)
            gcommit $flag $ai_flag "$@"

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

        audio-switcher = pkgs.writeShellApplication {
          name = "audio-switcher";
          runtimeInputs = [
            pkgs.pipewire
            pkgs.libnotify
          ];
          text = ''
            #!/usr/bin/env bash

            # Get available sinks
            sinks=$(wpctl status | awk '/Sinks:/,/Sources:/' | grep -E "^ *[0-9]+" | sed 's/^[* ]*//g')

            # Format for wofi (using bash parameter expansion)
            options="''${sinks//. /|}"

            # Show in wofi
            selected=$(echo "$options" | wofi --dmenu --prompt "Audio Device" --width 400)

            [ -z "$selected" ] && exit 0

            # Extract sink ID
            sink_id=$(echo "$selected" | cut -d'|' -f1)
            wpctl set-default "$sink_id"

            # Notify
            device_name=$(echo "$selected" | cut -d'|' -f2-)
            notify-send -u low "Audio Device" "Switched to: $device_name" -i audio-card
          '';
        };

        md2pdf = pkgs.writeShellApplication {
          name = "md2pdf";
          runtimeInputs = [
            pkgs.pandoc
            pkgs.texliveSmall
            pkgs.typst
          ];
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            # Display usage information
            show_usage() {
              cat << EOF
            Usage: md2pdf [OPTIONS] <input.md> [output.pdf]

            Convert Markdown files to PDF with multiple PDF engine options.

            OPTIONS:
              -e, --engine <engine>    PDF engine: xelatex (default), typst, wkhtmltopdf
              -t, --toc                Include table of contents
              -n, --number-sections    Number sections in the document
              --template <file>        Use custom template file
              --css <file>             Use custom CSS file (for HTML-based engines)
              --metadata <key=value>   Add metadata (can be used multiple times)
              -h, --help               Show this help message

            EXAMPLES:
              # Basic conversion (uses XeLaTeX by default)
              md2pdf document.md

              # With table of contents and numbered sections
              md2pdf -t -n document.md output.pdf

              # Using Typst engine
              md2pdf -e typst document.md

              # With custom template and metadata
              md2pdf --template custom.tex --metadata title="My Report" document.md

            ENGINES:
              xelatex      LaTeX-based (default, requires texlive)
              typst        Modern typesetting (faster, simpler)
              wkhtmltopdf  HTML-based (requires wkhtmltopdf package)
            EOF
            }

            # Default values
            engine="xelatex"
            toc=""
            number_sections=""
            template=""
            css=""
            metadata_args=()
            input_file=""
            output_file=""

            # Parse command-line arguments
            while [[ $# -gt 0 ]]; do
              case $1 in
                -e|--engine)
                  engine="$2"
                  shift 2
                  ;;
                -t|--toc)
                  toc="--toc"
                  shift
                  ;;
                -n|--number-sections)
                  number_sections="--number-sections"
                  shift
                  ;;
                --template)
                  template="--template=$2"
                  shift 2
                  ;;
                --css)
                  css="--css=$2"
                  shift 2
                  ;;
                --metadata)
                  metadata_args+=("--metadata" "$2")
                  shift 2
                  ;;
                -h|--help)
                  show_usage
                  exit 0
                  ;;
                -*)
                  echo "Error: Unknown option: $1" >&2
                  echo "Use -h or --help for usage information." >&2
                  exit 1
                  ;;
                *)
                  if [[ -z "$input_file" ]]; then
                    input_file="$1"
                  elif [[ -z "$output_file" ]]; then
                    output_file="$1"
                  else
                    echo "Error: Too many arguments" >&2
                    echo "Use -h or --help for usage information." >&2
                    exit 1
                  fi
                  shift
                  ;;
              esac
            done

            # Validate input file
            if [[ -z "$input_file" ]]; then
              echo "Error: No input file specified" >&2
              echo "Use -h or --help for usage information." >&2
              exit 1
            fi

            if [[ ! -f "$input_file" ]]; then
              echo "Error: Input file does not exist: $input_file" >&2
              exit 1
            fi

            # Auto-generate output filename if not provided
            if [[ -z "$output_file" ]]; then
              output_file="''${input_file%.md}.pdf"
            fi

            # Validate engine choice and check dependencies
            case "$engine" in
              xelatex|pdflatex)
                if ! command -v "$engine" &> /dev/null; then
                  echo "Error: $engine not found. Install texlive package." >&2
                  exit 1
                fi
                ;;
              typst)
                if ! command -v typst &> /dev/null; then
                  echo "Error: typst not found. Install typst package." >&2
                  exit 1
                fi
                ;;
              wkhtmltopdf)
                if ! command -v wkhtmltopdf &> /dev/null; then
                  echo "Error: wkhtmltopdf not found. Install wkhtmltopdf package." >&2
                  exit 1
                fi
                ;;
              *)
                echo "Error: Unknown engine: $engine" >&2
                echo "Supported engines: xelatex, pdflatex, typst, wkhtmltopdf" >&2
                exit 1
                ;;
            esac

            # Build pandoc command
            pandoc_cmd=(
              pandoc
              "$input_file"
              -o "$output_file"
              --pdf-engine="$engine"
            )

            # Add optional arguments
            [[ -n "$toc" ]] && pandoc_cmd+=("$toc")
            [[ -n "$number_sections" ]] && pandoc_cmd+=("$number_sections")
            [[ -n "$template" ]] && pandoc_cmd+=("$template")
            [[ -n "$css" ]] && pandoc_cmd+=("$css")

            # Add metadata if provided
            for meta in "''${metadata_args[@]}"; do
              pandoc_cmd+=("$meta")
            done

            # Execute conversion
            echo "Converting: $input_file → $output_file"
            echo "Engine: $engine"

            if "''${pandoc_cmd[@]}"; then
              echo "✓ Conversion successful: $output_file"
            else
              echo "✗ Conversion failed" >&2
              exit 1
            fi
          '';
        };

        gpu-toggle = pkgs.writeShellApplication {
          name = "gpu-toggle";
          runtimeInputs = [
            pkgs.pciutils
            pkgs.kmod
            pkgs.systemd
            pkgs.libnotify
          ];
          text = let
            constants = import ./shared/constants.nix;
            gpu = constants.gpu.pci.address;
            audio = constants.gpu.pci.audioAddress;
          in ''
            GPU_DEV="/sys/bus/pci/devices/${gpu}"
            AUDIO_DEV="/sys/bus/pci/devices/${audio}"

            notify_user() {
              if [ -n "''${SUDO_USER:-}" ]; then
                uid=$(id -u "$SUDO_USER")
                sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
                  notify-send -u normal "GPU Toggle" "$1" 2>/dev/null || true
              fi
            }

            gpu_on() {
              echo "Powering on NVIDIA GPU..."

              # Rescan PCI bus if device was removed
              if [ ! -d "$GPU_DEV" ]; then
                echo "GPU not on PCI bus, rescanning..."
                echo 1 > /sys/bus/pci/rescan
                sleep 2
              fi

              if [ ! -d "$GPU_DEV" ]; then
                echo "ERROR: GPU not found after rescan"
                exit 1
              fi

              # Set power control to on
              echo on > "$GPU_DEV/power/control"
              [ -d "$AUDIO_DEV" ] && echo on > "$AUDIO_DEV/power/control"
              sleep 1

              # Load NVIDIA kernel modules from current-system
              # (use -d to specify module directory in case running after nixos-rebuild test)
              modprobe -d /run/current-system/kernel-modules nvidia
              modprobe -d /run/current-system/kernel-modules nvidia_uvm
              modprobe -d /run/current-system/kernel-modules nvidia_drm
              modprobe -d /run/current-system/kernel-modules nvidia_modeset

              # Create NVIDIA device files (/dev/nvidia*, /dev/nvidiactl, etc.)
              # Required for CUDA to communicate with the GPU
              ${config.hardware.nvidia.package}/bin/nvidia-smi > /dev/null 2>&1 || true
              sleep 1

              # Start Ollama
              systemctl start ollama

              echo "GPU is ON, Ollama started"
              notify_user "NVIDIA GPU powered ON, Ollama started"
            }

            gpu_off() {
              echo "Powering off NVIDIA GPU..."

              # Stop Ollama
              systemctl stop ollama 2>/dev/null || true
              sleep 1

              # Unload NVIDIA kernel modules (reverse order)
              rmmod nvidia_modeset 2>/dev/null || true
              rmmod nvidia_drm 2>/dev/null || true
              rmmod nvidia_uvm 2>/dev/null || true
              rmmod nvidia 2>/dev/null || true

              # Set power control to auto (allows D3cold)
              if [ -d "$GPU_DEV" ]; then
                echo auto > "$GPU_DEV/power/control"
              fi
              if [ -d "$AUDIO_DEV" ]; then
                echo auto > "$AUDIO_DEV/power/control"
              fi

              sleep 2

              # Check if GPU entered low-power state
              if [ -d "$GPU_DEV" ]; then
                state=$(cat "$GPU_DEV/power_state" 2>/dev/null || echo "unknown")
                if [ "$state" = "D0" ]; then
                  echo "GPU still in D0, removing from PCI bus as fallback..."
                  echo 1 > "$GPU_DEV/remove"
                  [ -d "$AUDIO_DEV" ] && echo 1 > "$AUDIO_DEV/remove"
                  echo "GPU removed from PCI bus (rescan will restore it)"
                else
                  echo "GPU entered power state: $state"
                fi
              fi

              echo "GPU is OFF"
              notify_user "NVIDIA GPU powered OFF"
            }

            gpu_status() {
              if [ ! -d "$GPU_DEV" ]; then
                echo "GPU:    OFF (removed from PCI bus)"
                echo "Ollama: $(systemctl is-active ollama 2>/dev/null || true)"
                return
              fi

              power_state=$(cat "$GPU_DEV/power_state" 2>/dev/null || echo "unknown")
              driver=$(basename "$(readlink "$GPU_DEV/driver" 2>/dev/null)" 2>/dev/null || echo "none")
              ollama_state=$(systemctl is-active ollama 2>/dev/null || true)

              case "$power_state" in
                D0)       gpu_label="ON (D0 - fully powered, drawing ~10-15W)" ;;
                D3cold)   gpu_label="OFF (D3cold - powered down, ~0W)" ;;
                D3hot)    gpu_label="STANDBY (D3hot - low power, ~1-2W)" ;;
                *)        gpu_label="$power_state" ;;
              esac

              if [ "$driver" = "none" ]; then
                driver_label="no driver loaded"
              else
                driver_label="$driver"
              fi

              echo "GPU:    $gpu_label"
              echo "Driver: $driver_label"
              echo "Ollama: $ollama_state"
            }

            case "''${1:-status}" in
              on)   gpu_on ;;
              off)  gpu_off ;;
              status) gpu_status ;;
              *)
                echo "Usage: gpu-toggle {on|off|status}"
                echo "  on     - Power on GPU, load drivers, start Ollama"
                echo "  off    - Stop Ollama, unload drivers, power off GPU"
                echo "  status - Show GPU power state and Ollama status"
                exit 1
                ;;
            esac
          '';
        };

        project-init = pkgs.writeShellApplication {
          name = "project-init";
          runtimeInputs = [
            pkgs.fzf
            pkgs.coreutils
          ];
          text = ''
            TEMPLATES_DIR="/etc/nixos/templates"

            # Select template with fzf
            template=$(find "$TEMPLATES_DIR" -maxdepth 1 -mindepth 1 -printf '%f\n' | fzf --prompt="Select project type: ")

            if [[ -z "$template" ]]; then
              echo "No template selected, exiting."
              exit 0
            fi

            # Copy flake.nix if doesn't exist
            if [[ ! -f "flake.nix" ]]; then
              cp "$TEMPLATES_DIR/$template/flake.nix" .
              echo "Created flake.nix"
            else
              echo "flake.nix already exists, skipping"
            fi

            # Copy .envrc if doesn't exist
            if [[ ! -f ".envrc" ]]; then
              cp "$TEMPLATES_DIR/$template/.envrc" .
              direnv allow
              echo "Created .envrc and allowed direnv"
            else
              echo ".envrc already exists, skipping"
            fi

            # Stage files and commit
            git add flake.nix .envrc 2>/dev/null || true
            echo "Done! Run 'direnv reload' to activate the environment."
          '';
        };

      in
      [
        manteinance
        last_logs
        gcommit
        gpush
        uwsm-start-logged
        audio-switcher
        md2pdf
        gpu-toggle
        project-init
      ];
  };
}
