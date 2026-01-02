# Zsh Shell (System Configuration)
# User-level configuration in home-manager/programs/zsh.nix
{ ... }:

{
  programs.zsh = {
    enable = true;

    # Disable completion - configured in home-manager
    # https://github.com/nix-community/home-manager/issues/108
    enableCompletion = false;
  };
}
