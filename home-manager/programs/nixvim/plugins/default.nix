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
  ];

  programs.nixvim = {


    colorschemes.gruvbox.enable = true;

    plugins = {

    markdown-preview.enable = true;

      copilot-lua = {
        enable = true;
        panel.enabled = false;
        suggestion.enabled = false;
      };

      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
        };
      };
      nvim-autopairs.enable = true;
      nvim-colorizer = {
        enable = true;
        userDefaultOptions.names = false;
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
