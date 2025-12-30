{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
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

    # Cyber Tardigrade colorscheme
    colorschemes.base16 = {
      enable = true;
      colorscheme = {
        base00 = "#0d0d1a";  # bg_base
        base01 = "#1a1432";  # bg_surface
        base02 = "#2a2045";  # bg_elevated
        base03 = "#6b6b8a";  # fg_dim
        base04 = "#a8a8c0";  # fg_normal
        base05 = "#d4d4e8";  # fg_bright
        base06 = "#d4d4e8";  # fg_bright
        base07 = "#d4d4e8";  # fg_bright
        base08 = "#d55a5a";  # error (red)
        base09 = "#e86a30";  # accent_orange
        base0A = "#f0a050";  # accent_gold (yellow)
        base0B = "#5aaa7a";  # success (green)
        base0C = "#5a8fba";  # accent_cyan
        base0D = "#5a8fba";  # accent_cyan (blue)
        base0E = "#b55a9a";  # accent_magenta
        base0F = "#7a4a8a";  # accent_purple
      };
    };
  };

}
