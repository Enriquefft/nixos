{ config, pkgs, lib, inputs, ... }:

{

  nixpkgs.overlays = [

    inputs.nix-xilinx.overlay

  ];

}
