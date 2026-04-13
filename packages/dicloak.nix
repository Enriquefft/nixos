{ pkgs }:

let
  version = "2.8.14";

  src = pkgs.fetchurl {
    url = "https://cdn1.dicloak.net/app/release/prod/DICloak_${version}_linux_x64.deb";
    hash = "sha256-TKjhVVVvcCnYW8LpSTAkuyjO027tBiywPnowwIkdj04=";
  };

  dicloak-unwrapped = pkgs.stdenv.mkDerivation {
    pname = "dicloak-unwrapped";
    inherit version src;
    nativeBuildInputs = [ pkgs.dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out
      cp -r opt/DICloak/* $out/
      mkdir -p $out/share/applications $out/share/icons
      cp -r usr/share/icons/* $out/share/icons/ 2>/dev/null || true
      cp -r usr/share/applications/* $out/share/applications/ 2>/dev/null || true
    '';
  };
in
pkgs.buildFHSEnv {
  name = "dicloak";
  inherit version;

  targetPkgs = pkgs: with pkgs; [
    # Chromium / Electron core deps
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    glib
    gtk3
    pango
    cairo
    expat
    fontconfig
    freetype

    # X11 / display
    libx11
    libxcomposite
    libxdamage
    libxext
    libxrandr
    libxfixes
    libxcursor
    libxcb
    libxi
    libxrender
    libxtst
    libxscrnsaver
    libxshmfence

    # Graphics
    mesa
    libgbm
    libdrm
    libGL
    vulkan-loader
    libxkbcommon

    # Audio
    alsa-lib
    pipewire
    libpulseaudio

    # System
    systemd
    udev
  ];

  runScript = "${dicloak-unwrapped}/dicloak";

  meta = {
    description = "DiCloak anti-detect browser";
    homepage = "https://dicloak.com";
    platforms = [ "x86_64-linux" ];
  };
}
