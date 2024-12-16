{
  programs.nixvim.plugins = {
    web-devicons = { enable = true; };
    barbar = {
      enable = true;
      keymaps = {
        next.key = "<TAB>";
        previous.key = "<S-TAB>";
        close.key = "<C-w>";
      };
    };
  };
}
