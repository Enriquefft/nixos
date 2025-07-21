{
  description = "Nixos config flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim"; # Unstable
      inputs.nixpkgs.follows = "nixpkgs";

    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-xilinx = {
    #   url = "gitlab:doronbehar/nix-xilinx";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs =

    { self, nixpkgs, # nix-xilinx,
    ... }@inputs:
    let

      flake-overlays = [
        # nix-xilinx.overlay
      ];

    in {

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          inputs.home-manager.nixosModules.default
          inputs.nix-index-database.nixosModules.nix-index
          (import ./configuration.nix flake-overlays)
        ];
      };
    };
}
