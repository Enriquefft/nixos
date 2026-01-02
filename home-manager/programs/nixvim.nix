{ inputs, ... }:

let
  colors = (import ../../shared/colors.nix).cyberTardigrade;
in {
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

    # Cyber Tardigrade colorscheme from shared palette
    colorschemes.base16 = {
      enable = true;
      colorscheme = {
        base00 = "#${colors.bg_base}";
        base01 = "#${colors.bg_surface}";
        base02 = "#${colors.bg_elevated}";
        base03 = "#${colors.fg_dim}";
        base04 = "#${colors.fg_normal}";
        base05 = "#${colors.fg_bright}";
        base06 = "#${colors.fg_bright}";
        base07 = "#${colors.fg_bright}";
        base08 = "#${colors.error}";
        base09 = "#${colors.accent_orange}";
        base0A = "#${colors.accent_gold}";
        base0B = "#${colors.success}";
        base0C = "#${colors.accent_cyan}";
        base0D = "#${colors.accent_cyan}";
        base0E = "#${colors.accent_magenta}";
        base0F = "#${colors.accent_purple}";
      };
    };
  };

}
