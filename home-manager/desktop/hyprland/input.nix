# Hyprland Input Configuration
# Keyboard, mouse, and touchpad settings
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
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
  };
}
