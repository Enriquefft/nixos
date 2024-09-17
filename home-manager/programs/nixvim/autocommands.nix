{
  programs.nixvim.autoCmd = [
    # Vertically center document when entering insert mode
    {
      event = "InsertEnter";
      command = "norm zz";
    }

    # Open help in a vertical split
    {
      event = "FileType";
      pattern = "help";
      command = "wincmd L";
    }

    # Use *.v for verilog instead of vlang.
    {
      event = "BufWinEnter";
      pattern = "*.v";
      command = "set filetype=verilog";
    }

    # Use *.ebnf for Extended Backus-Naur Form.
    # EBNF is a notation for describing formal grammars.
    {
      event = "BufWinEnter";
      pattern = "*.ebnf";
      command = "set filetype=ebnf";
    }

  ];
}
