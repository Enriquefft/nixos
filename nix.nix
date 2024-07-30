{  ... }:

{
  nix = {

    settings = {

      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "hybridz" ];
      auto-optimise-store = true;

    };

    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };

  };

}
