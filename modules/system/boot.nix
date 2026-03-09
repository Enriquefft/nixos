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
        configurationLimit = 3;  # Keep max 3 boot entries to prevent /boot filling up
      };
      efi = {
        efiSysMountPoint = "/boot";
        canTouchEfiVariables = true;
      };
    };

    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_zen;

    kernelParams = [
      "i915.enable_psr=1"  # PSR1 - PSR2 causes i915 atomic update failures on Meteor Lake Arc, hanging Firefox GPU process
      "pcie_aspm=force"    # Force PCIe Active State Power Management for better battery life
      "acpi_backlight=native"  # Use Intel GPU native backlight control (required after blacklisting nvidia_wmi_ec_backlight)
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
