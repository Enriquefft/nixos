{ pkgs, ... }: {
  imports = [
    ./treesitter.nix
    ./lsp.nix
    ./comment.nix
    ./efm.nix
    ./none-ls.nix
    ./lualine.nix
    ./barbar.nix
    ./startify.nix
    ./obsidian.nix
    ./avante.nix
  ];

  programs.nixvim = {

    colorschemes.gruvbox.enable = true;

    plugins = {

      markdown-preview.enable = true;

      copilot-lua = {
        enable = true;
        autoLoad = true;
        settings = {

          panel = { enabled = false; };
          suggestion = { enabled = false; };
        };
      };

      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
        };
      };
      nvim-autopairs.enable = true;
      colorizer = {
        enable = true;
        settings = {
          user_default_options.names = false;

        };
      };
      oil.enable = true;
      trim = {
        enable = true;
        settings = {
          highlight = true;
          ft_blocklist = [ "lspinfo" "floaterm" ];
        };
      };
    };
  };
}
