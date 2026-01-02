# Bluetooth Configuration
# Disabled by default to save power, manual enable via bluetoothctl
{ ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };
}
