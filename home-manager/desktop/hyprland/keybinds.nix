# Hyprland Keybindings
# All keyboard and mouse bindings organized by category
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Core applications
      "$mainMod, C, killactive"
      "$mainMod, Q, exec, uwsm app -- kitty"
      "$mainMod, D, exec, uwsm app -- wofi --show drun"
      "$mainMod, E, exec, uwsm app -- kitty -e yazi"
      "$mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
      "$mainMod SHIFT, L, exec, hyprlock"
      "$mainMod, N, exec, pkill hyprsunset || hyprsunset -t 4500"
      "$mainMod, X, exec, wlogout"
      "$mainMod, B, exec, audio-toggle"
      "$mainMod, Escape, exec, hyprlock"

      # Voice dictation — press $mainMod+R to start, press again to stop.
      # GROQ_API_KEY is sourced from the sops-managed secret at
      # /run/secrets/yap/groq-api-key so it never lands in the Nix store.
      ''$mainMod, R, exec, GROQ_API_KEY="$(cat /run/secrets/yap/groq-api-key)" yap toggle''

      # Voice → Claude Code — press $mainMod+SHIFT+R to start, press again to stop.
      # Records voice, transcribes, routes to project via Haiku, opens Claude Code session.
      ''$mainMod SHIFT, R, exec, GROQ_API_KEY="$(cat /run/secrets/yap/groq-api-key)" yap toggle --exec claude-voice-router''

      # Window management
      "$mainMod, F, fullscreen"
      "$mainMod, Space, togglefloating"
      "$mainMod, M, exec, uwsm stop"
      "$mainMod, A, exec, audio-switcher"

      # Focus movement (vim keys)
      "$mainMod, h, movefocus, l"
      "$mainMod, j, movefocus, d"
      "$mainMod, k, movefocus, u"
      "$mainMod, l, movefocus, r"

      # Workspace switching (1-9)
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"

      # Move to workspace (SHIFT + 1-9)
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"

      # Screenshots (optimized for common usage)
      ", Print, exec, hyprshot -m region --clipboard-only"
      "$mainMod, Print, exec, hyprshot -m region"
      "SHIFT, Print, exec, hyprshot -m output --current --clipboard-only"
      "$mainMod SHIFT, Print, exec, hyprshot -m output --current"

      # Workspace switching with scroll
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ];

    # Repeatable bindings (hold to repeat)
    binde = [
      # Volume control (SwayOSD)
      ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
      ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
      ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"

      # Brightness control (SwayOSD - explicit device required after nvidia_wmi_ec_backlight blacklist)
      ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower --device intel_backlight"
      ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise --device intel_backlight"
    ];

    # Locked bindings (work even when lock screen is active)
    bindl = [
      ", switch:on:Lid Switch, exec, server-mode on"
      "$mainMod, O, exec, pkill -SIGRTMIN wvkbd-mobintl || wvkbd-mobintl"
    ];

    # Mouse bindings
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
  };
}
