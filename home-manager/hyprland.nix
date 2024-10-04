{ pkgs, ... }: {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,1.6";

      # Applications to execute once at startup
      exec-once = [
        "firefox"
        "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
      ];

      xwayland = { force_zero_scaling = true; };

      # Input configuration
      input = {
        kb_layout = "us";
        kb_options = "caps:swapescape";
        follow_mouse = "1";
        touchpad = { natural_scroll = "no"; };
        sensitivity = "-0.2";
      };

      # Decoration settings
      decoration = {
        rounding = "10";
        blur = {
          enabled = true;
          size = "3";
          passes = "1";
        };
        drop_shadow = "yes";
        shadow_range = "4";
        shadow_render_power = "3";
        "col.shadow" = "rgba(1a1a1aee)";
      };

      # Animation settings
      animations = {
        enabled = "yes";
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
      };

      # Gesture settings
      gestures = { workspace_swipe = "off"; };

      # Miscellaneous settings
      misc = { force_default_wallpaper = "-1"; };

      # Main modifier key
      "$mainMod" = "SUPER";

      # Keybindings
      bind = [
        # General keybindings
        "$mainMod, Q, exec, kitty"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, dolphin"
        "$mainMod, V, togglefloating,"
        "$mainMod, D, exec, wofi --show drun"
        "$mainMod, X, pin,"
        "$mainMod, F, fullscreen"
        # Move focus with arrow keys on DVORAK
        "$mainMod, H, movefocus, l"
        "$mainMod, S, movefocus, r"
        "$mainMod, N, movefocus, u"
        "$mainMod, T, movefocus, d"
        # Move focus with arrow keys
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        "$mainMod, J, movefocus, d"
        # Switch workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"
        # Move active window to a workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        # Workspace switching with scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
        # Screenshot keybindings
        ", PRINT, exec, hyprshot -m output --current --clipboard-only" # screenshot monitor
        "$mainMod, PRINT, exec, hyprshot -m region --clipboard-only" # screenshot region
        "$shiftMod, PRINT, exec, hyprshot -m output --current" # screenshot monitor & save
        "$mainMod&$shiftMod, PRINT, exec, hyprshot -m region" # screenshot region & save

      ];
      binde = [
        # Volume control
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        # Brightness control
        ", XF86MonBrightnessDown, exec, light -U 5"
        ", XF86MonBrightnessUp, exec, light -A 5"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
