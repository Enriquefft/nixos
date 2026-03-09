{
  description = "Nixos config flake";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim"; # Unstable
      # url = "github:nix-community/nixvim/nixos-25.05";
      # inputs.nixpkgs.follows = "nixpkgs";

    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zeroclaw = {
      url = "github:zeroclaw-labs/zeroclaw";
    };

    nix-steipete-tools = {
      url = "github:openclaw/nix-steipete-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kapso-whatsapp-plugin = {
      url = "path:/home/hybridz/Projects/openclaw-kapso-whatsapp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yap = {
      url = "path:/home/hybridz/Projects/yap";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-xilinx = {
    #   url = "gitlab:doronbehar/nix-xilinx";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs =

    {
      self,
      nixpkgs, # nix-xilinx,
      ...
    }@inputs:
    let

      flake-overlays = [
        # nix-xilinx.overlay
      ];

    in
    {

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          antigravity = inputs.antigravity-nix.packages.x86_64-linux.default;
        };
        modules = [
          inputs.home-manager.nixosModules.default
          inputs.nix-index-database.nixosModules.nix-index
          inputs.sops-nix.nixosModules.sops
          inputs.yap.nixosModules.default
          (import ./configuration.nix flake-overlays)
        ];
      };
    };
}
