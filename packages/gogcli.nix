{ pkgs }:

let
  version = "latest";

  # GOG CLI typically installs as a single binary
  # This package downloads and wraps the official installer
  gogcli-bin = pkgs.fetchurl {
    url = "https://gogcli.sh/";
    sha256 = "0hmfg6pz045kqb97lwdxaaa4w8w1gcph91dn3kljhh561xyqrqn7";
  };
in

pkgs.stdenv.mkDerivation {
  pname = "gogcli";
  inherit version;

  src = gogcli-bin;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/gogcli
    chmod +x $out/bin/gogcli
  '';

  meta = with pkgs.lib; {
    description = "GOG.com CLI tool for managing games";
    homepage = "https://gogcli.sh/";
    license = licenses.free;
    platforms = platforms.linux;
  };
}
