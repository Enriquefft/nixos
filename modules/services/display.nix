# Display Services
# Screen color temperature and keyboard layout
{ ... }:

let
  constants = import ../../shared/constants.nix;
in {
  services = {
    # Blue light filter based on time of day
    redshift = {
      enable = true;
      brightness = {
        day = "1";
        night = "0.8";
      };
      temperature = {
        day = 5500;
        night = 3700;
      };
    };

    # X server configuration (keyboard layout)
    xserver = {
      xkb = {
        layout = "us";
        variant = "intl";
        options = "caps:swapescape";
      };
    };

    # Touchpad support
    libinput.enable = true;
  };
}
