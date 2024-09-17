{ pkgs, ... }: {
  programs.nixvim.filetype = {

    extension = { rasi = "rasi"; };
    pattern = { ".*.v" = "verilog"; };
  };
}
