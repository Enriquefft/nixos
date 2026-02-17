# Ollama AI Service
# CUDA-accelerated LLM inference, started on-demand via gpu-toggle
{ lib, config, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Don't auto-start Ollama - use 'sudo gpu-toggle on' to start with GPU
  systemd.services.ollama.wantedBy = lib.mkForce [];

  # Add NVIDIA CUDA libraries to Ollama's environment
  # Required because GPU drivers are blacklisted and loaded on-demand
  systemd.services.ollama.environment = {
    LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";
  };
}
