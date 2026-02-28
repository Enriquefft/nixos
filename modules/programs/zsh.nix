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

  # Suppress "insecure directories" warning when root uses zsh
  # (completion dirs are owned by normal user via home-manager)
  environment.variables.ZSH_DISABLE_COMPFIX = "true";

  # System-wide zsh init so all users (including root) get zoxide + cd alias
  programs.zsh.interactiveShellInit = ''
    eval "$(zoxide init zsh)"
    alias cd=z
  '';
}
