{ pkgs, ... }:
let
  colors = (import ../shared/colors.nix).cyberTardigrade;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {

      enable = false;

    };

    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,1.6";

      # Applications to execute once at startup
      exec-once = [
        "uwsm app -- firefox"
        "uwsm app -- waybar"
        "uwsm app -- hyprpaper"
        "uwsm app -- wl-paste --watch cliphist store"
        "uwsm app -- ${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
      ];

      xwayland = {
        force_zero_scaling = true;
      };

      # Input configuration
      input = {
        kb_layout = "us";
        kb_variant = "intl";
        kb_options = "compose:rctrl";
        follow_mouse = "1";
        mouse_refocus = "false";
        touchpad = {
          natural_scroll = "no";
        };
        sensitivity = "-0.2";
      };

      cursor = {
        no_warps = true;

      };

      # General settings
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgb(${colors.accent_orange})";
        "col.inactive_border" = "rgb(${colors.border})";
      };

      # Decoration settings
      decoration = {
        rounding = 8;
        blur = {
          enabled = false;
          size = 6;
          passes = 2;
        };
        shadow = {
          enabled = false;
          color = "rgba(${colors.accent_orange}33)";
        };
      };

      # Animation settings
      animations = {
        enabled = true;
        bezier = "easeOut, 0.25, 1, 0.5, 1";
        animation = [
          "windows, 1, 3, easeOut"
          "workspaces, 1, 4, easeOut, slide"
          "fade, 1, 3, default"
        ];
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
      };

      # Miscellaneous settings
      misc = {
        force_default_wallpaper = "-1";
        vfr = true;
      };

      # Main modifier key
      "$mainMod" = "SUPER";

      # Keybindings
      bind = [
        # Core applications
        "$mainMod, C, killactive"
        "$mainMod, Q, exec, uwsm app -- kitty"
        "$mainMod, D, exec, uwsm app -- wofi --show drun"
        "$mainMod, E, exec, uwsm app -- kitty -e yazi"
        "$mainMod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
        "$mainMod, L, exec, hyprlock"
        "$mainMod, N, exec, pkill hyprsunset || hyprsunset -t 4500"
        "$mainMod, X, exec, wlogout"
        "$mainMod, B, exec, pkill waybar || uwsm app -- waybar"
        "$mainMod, Escape, exec, hyprlock"

        # Window management
        "$mainMod, F, fullscreen"
        "$mainMod, Space, togglefloating"
        "$mainMod, M, exec, uwsm stop"
        "$mainMod, A, exec, audio-switcher"  # Audio device switcher

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

        # Screenshots (optimized for most common usage)
        ", Print, exec, hyprshot -m region --clipboard-only" # Most used: region → clipboard
        "$mainMod, Print, exec, hyprshot -m region" # Save region to file
        "SHIFT, Print, exec, hyprshot -m output --current --clipboard-only" # Monitor → clipboard
        "$mainMod SHIFT, Print, exec, hyprshot -m output --current" # Save monitor to file

        # Workspace switching with scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];
      binde = [
        # Volume control (SwayOSD)
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        # Brightness control (SwayOSD)
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };
  };
}
