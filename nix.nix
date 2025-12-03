{ ... }:

{
  nix = {

    settings = {

      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "hybridz"
      ];
      auto-optimise-store = true;
      download-buffer-size = 524288000 * 2; # 500 MiB * 2

    };

    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };

  };

}
