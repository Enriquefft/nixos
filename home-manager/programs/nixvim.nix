{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./autocommands.nix
    ./completion.nix
    ./keymappings.nix
    ./options.nix
    ./plugins
    ./filetype.nix
    ./todo.nix
    ./extra.nix
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
