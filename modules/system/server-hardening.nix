# Server Hardening
# Reliability, monitoring, and kernel tuning for server mode
# All settings are always-on — they benefit desktop mode too
{ lib, pkgs, ... }:

{
  # === OOM Protection ===
  # Kills memory hogs before the system freezes
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;   # Act when <5% RAM free
    freeSwapThreshold = 10; # Act when <10% swap free
    enableNotifications = true;
  };

  # === Disk Health (SMART) ===
  services.smartd = {
    enable = true;
    autodetect = true; # Monitor all drives
    defaults.monitored = "-a -o on -S on -n standby,q";
  };

  # === SSD TRIM ===
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # === Journal Retention ===
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=30day
  '';

  # Resolve earlyoom vs smartd conflict on systembus-notify
  services.systembus-notify.enable = lib.mkForce true;

  # === Hardware Watchdog ===
  # Auto-reboots on system hang — critical for headless server mode
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };

  # === Brute-Force Protection ===
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment.enable = true;
  };

  # === Kernel Tuning ===
  boot.kernel.sysctl = {
    # File handles — prevent "too many open files" under load
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

    # Network buffers — better throughput for SSH/Tailscale
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.core.netdev_max_backlog" = 5000;

    # TCP tuning
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.ipv4.tcp_fastopen" = 3;

    # VM pressure — prefer keeping process pages over cache
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };
}
