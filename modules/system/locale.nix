# Internationalization and Console Configuration
# TTY console with Cyber Tardigrade color scheme
{ pkgs, ... }:

let
  constants = import ../../shared/constants.nix;
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
  # Time zone and location
  time = {
    timeZone = constants.location.timezone;
    hardwareClockInLocalTime = true;
  };

  location = {
    # Hardcoded location settings saves the need for geolocation services
    latitude = constants.location.latitude;
    longitude = constants.location.longitude;
  };

  # Internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "es_PE.UTF-8/UTF-8"
    ];
  };

  # Console configuration with Cyber Tardigrade theme
  console = {
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    earlySetup = true;
    useXkbConfig = true;

    # ANSI colors from shared palette
    colors = [
      colors.bg_base
      colors.error
      colors.success
      colors.accent_gold
      colors.accent_cyan
      colors.accent_magenta
      colors.accent_cyan
      colors.fg_normal
      colors.fg_dim
      colors.terminal_error
      colors.terminal_success
      colors.terminal_modified
      colors.terminal_cyan
      colors.accent_magenta
      colors.terminal_cyan
      colors.fg_bright
    ];
  };
}
