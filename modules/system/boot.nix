# Boot Configuration
# Systemd-boot with Zen kernel and Plymouth splash screen
{ pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        editor = false;  # Disable boot entry editing for security
        consoleMode = "max";  # Use maximum resolution for boot menu
      };
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;

    kernelParams = [
      "i915.enable_psr=0"  # Disable Panel Self Refresh - fixes screen flickering on Framework 13 Intel
      "quiet"           # Suppress most kernel messages
      "splash"          # Enable Plymouth splash screen
      "vt.global_cursor_default=0"  # Hide blinking cursor
      "rd.systemd.show_status=false"  # Hide systemd status during initrd
      "rd.udev.log_level=3"  # Reduce udev logging in initrd
      "udev.log_priority=3"  # Reduce udev logging after boot
    ];

    plymouth = {
      enable = true;
      font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
      themePackages = [ pkgs.adi1090x-plymouth-themes ];
      theme = "rings";  # Minimal theme matching research terminal aesthetic
    };
  };
}
