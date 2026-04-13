{ config, pkgs, ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        # Dim screen after 5 minutes
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 10%";
          on-resume = "brightnessctl -r";
        }
        # Auto-lock disabled — no fingerprint reader and keyboard keys are unreliable
        # Lock manually with Super+L when you have a working keyboard
        # {
        #   timeout = 600;
        #   on-timeout = "loginctl lock-session";
        # }
        # Turn off screen after 15 minutes
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # No auto-suspend — AC-only system, no battery
        # Use wlogout (Super+X) for manual suspend
      ];
    };
  };
}
