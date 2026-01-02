# Development Tools
# nix-ld for running unpatched binaries, nix-index for command-not-found, light for backlight control
{ pkgs, ... }:

{
  programs = {
    # Command-not-found replacement using nix-index
    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # Backlight control
    light.enable = true;

    # Run unpatched dynamic binaries on NixOS
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Core C/C++ runtime
        stdenv.cc.cc.lib

        # Common system libraries
        zlib
        openssl
        curl

        # Graphics/GUI (for Electron apps like Slack, Discord, VSCode)
        glib
        nss
        nspr
        dbus
        atk
        cups
        libdrm
        gtk3
        pango
        cairo
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libxcb
        mesa
        expat
        alsa-lib

        # Development tools common deps
        libffi
        ncurses
        readline
      ];
    };
  };
}
