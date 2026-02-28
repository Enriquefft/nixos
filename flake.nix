{
  description = "Nixos config flake";

  inputs = {

    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kapso-whatsapp-plugin = {
      url = "github:Enriquefft/openclaw-kapso-whatsapp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openclaw = {
      # My openclaw config
      url = "path:./openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-openclaw.follows = "nix-openclaw";
      inputs.kapso-whatsapp-plugin.follows = "kapso-whatsapp-plugin";
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
        inputs.nix-openclaw.overlays.default
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
          (import ./configuration.nix flake-overlays)
        ];
      };
    };
}
