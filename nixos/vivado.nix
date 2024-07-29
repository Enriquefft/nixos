{
inputs = {
  # ...
  nix-xilinx = {
    # Recommended if you also override the default nixpkgs flake, common among
    # nixos-unstable users:
    #inputs.nixpkgs.follows = "nixpkgs";
    url = "gitlab:doronbehar/nix-xilinx";
  };
  # ...
  outputs = { self, nixpkgs, nix-xilinx }:
  let
    flake-overlays = [
      nix-xilinx.overlay
    ];
  in {
    nixosConfigurations = (
      HOSTNAME = nixpkgs.lib.nixosSystem {
        modules = [ (import ./configuration.nix flake-overlays) ];
      };
    );
  };
};
}
