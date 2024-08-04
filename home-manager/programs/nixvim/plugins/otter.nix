{
  programs.nixvim.plugins.otter = {

    enable = true;

    settings = {

      handle_leading_whitespace = false;

      lsp = {
        diagnostic_update_events = [ "BufWritePost" "InsertLeave" ];

      };

    };

  };

}
