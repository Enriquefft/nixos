{ pkgs, ... }:
{
  programs.nixvim = {
    extraConfigLua = ''
      vim.lsp.config("verible", {
          cmd = {
              'verible-verilog-ls',
              '--rules=parameter-name-style=localparam_style:ALL_CAPS,-always-comb,-explicit-parameter-storage-type,-unpacked-dimensions-range-ordering,-no-tabs'
          }
      }
      );



    '';

    extraPlugins = with pkgs.vimPlugins; [ ];
  };

}
