{
  description = "ZSA Voyager keyboard development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    oryx-bench = {
      url = "path:/home/hybridz/Projects/oryx-bench";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, oryx-bench, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          oryx-bench.packages.${system}.default

          # Build toolchain (Docker handles most of this, but needed for native backend)
          pkgs.qmk
          pkgs.gcc-arm-embedded
          pkgs.zig

          # Flash
          pkgs.wally-cli
          pkgs.kontroll
        ];
      };
    };
}
