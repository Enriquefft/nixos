# yap transcription secrets.
#
# The Groq API key is surfaced at /run/secrets/yap/groq-api-key with
# mode 0400 and owner `hybridz`. The Hyprland keybind reads this file
# at invocation time and exports it as GROQ_API_KEY in yap's process
# environment (see home-manager/desktop/hyprland/keybinds.nix). The
# key is deliberately NOT placed in services.yap.settings.transcription.api_key
# because yap's NixOS module renders that into /etc/yap/config.toml via
# the Nix store, which is world-readable.
{ ... }:

{
  sops.secrets."yap/groq-api-key" = {
    sopsFile = ../../secrets/yap.yaml;
    owner = "hybridz";
    mode = "0400";
  };
}
