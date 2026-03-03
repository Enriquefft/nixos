# Hyprland Window Rules
# Controls window placement, focus, and behavior
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Kiro workspace (8) rules - parallel-safe
    # Allows Kiro to operate on workspace 8 while user works elsewhere
    windowrulev2 = [
      # Open on workspace 8, don't switch to it
      "workspace 8 silent, class:kiro-browser"
      
      # Never steal focus from user's current window
      "stayfocused, class:kiro-browser"
      
      # Don't focus on creation
      "nofocus, class:kiro-browser"
    ];
  };
}
