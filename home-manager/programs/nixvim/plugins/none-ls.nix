{
  programs.nixvim.plugins.none-ls = {

    enable = true;

    enableLspFormat = true;

    sources = {
      formatting = {
        nixfmt.enable = true;
        # prettierd = {
        #   disableTsServerFormatter = true;
        #   enable = true;
        # };
        biome.enable = true;

        clang_format.enable = true;
        cmake_format.enable = true;
        verible_verilog_format.enable = true;
      };
      diagnostics = {
        cmake_lint.enable = true;

      };
    };
  };

}
