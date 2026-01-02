# Audio Configuration
# PipeWire replacing PulseAudio for better Bluetooth and low-latency support
{ ... }:

{
  # Disable PulseAudio (replaced by PipeWire)
  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;

    pulse.enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };
    jack.enable = true;
  };
}
