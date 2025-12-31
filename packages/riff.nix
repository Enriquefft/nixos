{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, meson
, ninja
, pkg-config
, wrapGAppsHook4
, blueprint-compiler
, desktop-file-utils
, gtk4
, libadwaita
, gst_all_1
, alsa-lib
, openssl
, libpulseaudio
}:

rustPlatform.buildRustPackage rec {
  pname = "riff";
  version = "25.11";

  src = fetchFromGitHub {
    owner = "Diegovsky";
    repo = "riff";
    rev = "v${version}";
    hash = "sha256-j5PZXXGInA03V3Lfu+QUgeHw8583XvJZyW67VcDe980=";
  };

  cargoHash = "sha256-8gJILK9A97PAb/Q1z+IvW54WuwoZZSKxlJJUt7dwQWE=";

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wrapGAppsHook4
    blueprint-compiler
    desktop-file-utils
  ];

  buildInputs = [
    gtk4
    libadwaita
    openssl
    alsa-lib
    libpulseaudio
  ] ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
  ]);

  # Use meson for building
  buildPhase = ''
    runHook preBuild
    meson setup build --prefix=$out -Dbuildtype=release
    ninja -C build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ninja -C build install
    runHook postInstall
  '';

  meta = with lib; {
    description = "A native Spotify client for GNOME (premium accounts only)";
    homepage = "https://github.com/Diegovsky/riff";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
