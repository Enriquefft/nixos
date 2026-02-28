{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{

  imports = [
    # Desktop environment
    ./desktop/hyprland
    ./programs/waybar.nix
    ./programs/wofi.nix
    ./programs/hyprlock.nix
    ./programs/hypridle.nix
    ./programs/wallpaper.nix
    ./cursor.nix

    # Services
    ./services/notifications.nix

    # Programs
    ./programs/zsh.nix
    ./programs/kitty.nix
    ./programs/nixvim.nix
    ./programs/swayosd.nix
    ./programs/openclaw.nix
  ];

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };

  xdg = {
    configFile."mimeapps.list".force = true;
    enable = true;
    mime.enable = true;
    mimeApps = {
      defaultApplications = {
        "application/pdf" = "firefox.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "x-scheme-handler/figma" = "figma-linux.desktop";

      };
      enable = true;
    };
    userDirs = {
      createDirectories = true;

      enable = true;
    };

    portal = {

      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.hyprland ];
    };

    # desktopEntries = {
    #
    #   Vivado = {
    #     name = "vivado";
    #     exec = ''
    #       sh -c "nix run gitlab:doronbehar/nix-xilinx#vivado"
    #     '';
    #     terminal = false;
    #     categories = [ "Utility" "Development" "IDE" ];
    #   };
    # };
  };

  # GTK theme configuration (fixes white-on-white in figma-linux)
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "hybridz";
  home.homeDirectory = "/home/hybridz";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [

    verible

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/hybridz/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";

  };

  programs = {

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    git = {

      enable = true;

      settings = {
        user = {

          name = "Enriquefft";
          email = "enriquefft2001@gmail.com";
        };
        init.defaultBranch = "main";
        safe.directory = "/etc/nixos";

      };

      ignores = [ ".direnv" ];

    };

    direnv = {

      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;

    };
  };
}
