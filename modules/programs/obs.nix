{ pkgs, ... }:

let
  # droidcam-obs is built against ffmpeg 7.x (libavcodec major=61), but OBS 32.x
  # ships ffmpeg 8.x (libavcodec major=62). OBS loads plugins with RTLD_GLOBAL, so
  # avcodec_version() resolves to OBS's ffmpeg 8.0 at runtime, failing the strict
  # "version must be <= LIBAVCODEC_VERSION_MAJOR" guard in src/plugin.cc:109.
  # Patch the check away — the plugin works fine against ffmpeg 8.x at runtime.
  droidcam-obs-patched = pkgs.obs-studio-plugins.droidcam-obs.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i 's/AV_VERSION_MAJOR(avcodec_version()) > LIBAVCODEC_VERSION_MAJOR/false/' src/plugin.cc
    '';
  });
in
{
  programs = {
    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = [
        droidcam-obs-patched
      ];
    };
  };
}
