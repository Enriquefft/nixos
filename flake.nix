{
  description = "Nixos config flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      #url = "github:nix-community/nixvim"; # Unstable
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";

    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-xilinx = { url = "gitlab:doronbehar/nix-xilinx"; };

  };

  outputs =

    { self, nixpkgs, nix-xilinx, ... }@inputs: {

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.home-manager.nixosModules.default
          inputs.nix-index-database.nixosModules.nix-index
          (import ./overlays nix-xilinx)
        ];
      };
    };
}
