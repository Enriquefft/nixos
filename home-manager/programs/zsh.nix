{ config, pkgs, lib, ... }:

{
  programs.zsh = rec {

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./p10k-config;
        file = "p10k.zsh";
      }

    ];

    autocd = true;

    dotDir = ".config/zsh";

    envExtra = "";

    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    loginExtra = ''[ "$(tty)" = "/dev/tty1" ] && Hyprland'';

    shellAliases = rec {

      cd = "z";

      ".." = "cd ..";
      "..." = "cd ../..";

      ls =
        "${pkgs.eza}/bin/exa --color=auto --group-directories-first --classify";
      lst = "${ls} --tree";
      la = "${ls} --all";
      ll = "${ls} --all --long --header --group";
      llt = "${ll} --tree";
      tree = "${ls} --tree";

      # Interactive & informative
      cp = "cp -iv";
      ln = "ln -v";
      mkdir = "mkdir -vp";
      mv = "mv -iv";

      up = "doas nixos-rebuild switch";

      # Config aliases
      nix-conf = "vim /etc/nixos/configuration.nix";
      nix-apps = "vim /etc/nixos/applications.nix";
      zsh-conf = "vim /etc/nixos/home-manager/programs/zsh.nix";

      flake-init =
        "nix flake new -t github:enriquefft/flake-template#dev-shell";

      # TODO: move to dev shells
      compile =
        "clang++ -std=c++2b -Weverything -Wno-c++14-compat -Wno-c++98-compat -Wno-string-compare -ferror-limit=1 -fsanitize=address -g";
      compilemain =
        "clang++ -std=c++2b -Weverything -Wno-c++14-compat -Wno-c++98-compat -Wno-string-compare -ferror-limit=1 -fsanitize=address -g *.cpp -o main";

      con = "nmcli connection up";
      airplane =
        "nmcli radio wifi off; nmcli radio bluetooth off; nmcli radio wwan off";

      svim = "sudoedit";

      zreload =
        "export ZSH_RELOADING_SHELL=1; source $ZDOTDIR/.zshenv; source $ZDOTDIR/.zshrc; unset ZSH_RELOADING_SHELL";

      zsh-fix-hist =
        "strings ${history.path} > ${history.path} && fc -R ${history.path}";

      clone = "git clone";

    };

    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      share = false; # Share history between all shell sessions.
      ignoreDups = true;
      ignoreAllDups = true;

      expireDuplicatesFirst = true;
      ignoreSpace = true;
    };

    profileExtra = ''
      setopt incappendhistory
      setopt histfindnodups
      setopt histreduceblanks
      setopt histverify
      setopt correct                                                  # Auto correct mistakes
      setopt extendedglob                                             # Extended globbing. Allows using regular expressions with *
      setopt nocaseglob                                               # Case insensitive globbing
      setopt rcexpandparam                                            # Array expension with parameters
      #setopt nocheckjobs                                             # Don't warn about running processes when exiting
      setopt numericglobsort                                          # Sort filenames numerically when it makes sense
      setopt nobeep                                                   # Disable beep
      setopt appendhistory                                            # Immediately append history instead of overwriting
      unsetopt histignorealldups                                      # If a new command is a duplicate, do not remove the older one
      setopt interactivecomments
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"       # Colored completion (different colors for dirs/files/etc)
      zstyle ':completion:*' rehash true                              # automatically find new executables in path
    '';

    zplug = {
      enable = true;
      plugins = [{
        name = "romkatv/powerlevel10k";
        tags = [ "as:theme" "depth:1" ];
      } # Installations with additional options. For the list of options, please refer to Zplug README.
        ];
    };

  };

}
