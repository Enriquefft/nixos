# Server Mode — automatic lid-open handler via acpid
# Complements the Hyprland bindl (lid close) and server-mode script
{ ... }:

{
  # Clean server-mode flag on boot (in case of hard power-off)
  systemd.tmpfiles.rules = [
    "r /tmp/server-mode - - - - -"
  ];

  services.acpid = {
    enable = true;

    # acpid passes the full event as a single string in $1
    # e.g. "button/lid LID open" or "button/lid LID close"
    lidEventCommands = ''
      if echo "$1" | grep -q " open$"; then
        if [ -f /tmp/server-mode ]; then
          /run/current-system/sw/bin/tlp ac
          rm -f /tmp/server-mode
          systemctl restart getty@tty1
        fi
      fi
    '';
  };
}
