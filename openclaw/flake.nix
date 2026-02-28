{
  description = "Personal OpenClaw agent configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
    kapso-whatsapp-plugin = {
      url = "github:Enriquefft/openclaw-kapso-whatsapp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-openclaw, kapso-whatsapp-plugin }: {
    homeManagerModules.default =
      import ./module.nix { inherit nix-openclaw kapso-whatsapp-plugin; };
  };
}
