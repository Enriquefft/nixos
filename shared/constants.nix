# Centralized configuration constants
# Single source of truth for all hardcoded values
{
  # System identification
  hostname = "nixos";

  # Location (Lima, Peru) - hardcoded to avoid geolocation services
  location = {
    latitude = -12.11;
    longitude = -76.98;
    timezone = "America/Lima";
  };

  # Network
  dns = {
    primary = "8.8.8.8";    # Google DNS
    secondary = "8.8.4.4";
  };

  # Battery management
  battery = {
    device = "BAT0";

    # TLP charge thresholds (battery longevity)
    charge = {
      start = 40;  # Begin charging when below 40%
      stop = 85;   # Stop charging at 85%
    };

    # Low battery warnings
    notify = 10;   # Show notification at 10%
    suspend = 5;   # Auto-suspend at 5%

    # Visual effects threshold
    effects = 90;  # Disable blur/shadow below 90%
  };

  # Display
  display = {
    scale = 1.6;  # HiDPI scaling factor
  };

  # User
  user = {
    name = "hybridz";
    description = "Enrique Flores";
  };
}
