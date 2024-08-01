{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./nixvim/autocommands.nix
    ./nixvim/completion.nix
    ./nixvim/keymappings.nix
    ./nixvim/options.nix
    ./nixvim/plugins
    ./nixvim/filetype.nix
    ./nixvim/todo.nix
    ./nixvim/extra.nix
  ];

  home.shellAliases.v = "nvim";
  programs.nixvim = {

    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    withNodeJs = true;

    luaLoader.enable = true;
  };

}
