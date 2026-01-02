# Graphics Configuration
# Intel GPU with hardware video acceleration
{ pkgs, ... }:

{
  hardware = {
    cpu.intel.updateMicrocode = true;

    enableAllFirmware = true;
    enableRedistributableFirmware = true;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [ vpl-gpu-rt ];
    };
  };
}
