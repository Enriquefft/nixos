{ pkgs, ... }: {
  programs.nixvim.filetype = {

    extension = {
      rasi = "rasi";
      v = "verilog";
    };
  };
}
