{ pkgs, lib, config, inputs, ... }: {
  systemd.user.timers."lowbatt" = {
    Unit = { Description = "Battery level checker"; };
    Timer = {
      OnUnitInactiveSec = "2m";
      Unit = "lowbatt.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
  systemd.user.services."lowbatt" = let
    notifyCapacity = config.services.batteryLevel.notifyCapacity or 20;
    suspendCapacity = config.services.batteryLevel.suspendCapacity or 10;
    device = config.services.batteryLevel.device or "BAT0";
  in {
    Unit = { Description = "Battery level notifier"; };
    Service = {
      ExecStart = "${pkgs.writeShellScript "notify-batt" ''
        #!/run/current-system/sw/bin/bash

        export battery_capacity=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${device}/capacity)
        export battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${device}/status)

        if [[ $battery_capacity -le ${builtins.toString notifyCapacity}
            && $battery_status = "Discharging" ]]; then
            ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Low" "You should probably plug-in."
        fi

        if [[ $battery_capacity -le ${builtins.toString suspendCapacity}
            && $battery_status = "Discharging" ]]; then
            ${pkgs.libnotify}/bin/notify-send --urgency=critical --hint=int:transient:1 --icon=battery_empty "Battery Critically Low" "Computer will suspend in 60 seconds."
            sleep 60s

            battery_status=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/${device}/status)
            if [[ $battery_status = "Discharging" ]]; then
                systemctl suspend
            fi
        fi
      ''}";
    };
  };
}
