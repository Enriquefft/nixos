# Yap - Hold-to-Talk Voice Dictation
# https://github.com/hybridz/yap
#
# Driven by the Hyprland keybind ($mainMod+R → yap toggle), so the
# systemd daemon is disabled. Hotkey is parked on KEY_F24 (no-op key)
# and `user` is null — no evdev listener means no input-group grant.
#
# Transcription runs on Groq's whisper-large-v3-turbo. GROQ_API_KEY is
# injected into the process environment by the Hyprland keybind, which
# reads it from the sops-managed secret at /run/secrets/yap/groq-api-key
# (see ./yap-secrets.nix). Keeping the key out of /etc/yap/config.toml
# is required because that file lives in the world-readable Nix store.
{ ... }:

{
  services.yap = {
    enable = true;
    daemon.enable = false;
    user = null;

    settings = {
      general.hotkey = "KEY_F24";
      transcription.backend = "groq";
      transcription.model = "whisper-large-v3-turbo";
      transcription.language = "es";
      injection.app_overrides = [
        { match = "kitty"; strategy = "wayland"; append_enter = true; }
      ];
    };
  };
}
