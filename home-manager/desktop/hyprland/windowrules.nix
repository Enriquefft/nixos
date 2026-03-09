# Hyprland Window Rules
# Controls window placement, focus, and behavior
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Kiro workspace (8) rules - parallel-safe
    # Allows Kiro to operate on workspace 8 while user works elsewhere
    windowrule = [
      # Open on workspace 8, don't switch to it; never steal focus from user
      "match:class kiro-browser, workspace 8 silent, stay_focused on, no_focus on"

      # ZeroClaw browser automation — opens on workspace 8 (watch by switching there)
      "match:class zeroclaw-browser, workspace 8 silent"

      # Whispering — float with a comfortable size
      "match:class whispering, float on, size 900 650, center on"
    ];
  };
}
