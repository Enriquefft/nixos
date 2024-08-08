nix-xilinx:
{ config, pkgs, lib, inputs, ... }:

{

  # nixpkgs.overlays = [ inputs.nix-xilinx.overlay ];
  nixpkgs.overlays = [ nix-xilinx.overlay ];

}
