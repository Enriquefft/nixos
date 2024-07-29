{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;

      nixvimInjections = true;

      folding = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        incremental_selection.enable = true;
      };
    };

    refactoring = { enable = true; };
    # treesitter-refactor = {
    #   enable = true;
    #   highlightDefinitions = {
    #     enable = true;
    #     # Set to false if you have an `updatetime` of ~100.
    #     clearOnCursorMove = false;
    #   };
    # };

    treesitter-context = { enable = true; };

    hmts.enable = true;
  };
}
