# trace: evaluation warning: Passing a attribute set containing name, icon.icon, extraConfig for `home-manager.users.hybridz.programs.nixvim.plugins.lualine.settings.sections.lualine_x."[definition 1-entry 2]"' is deprecated, use (attribute set of anything) or raw lua code instead. Definitions:
# - In `/nix/store/9kha32asg2qny93n4kbwd5w3jx126l3k-source/home-manager/programs/nixvim/plugins/lualine.nix':
#     {
#       color = {
#         fg = "#ffffff";
#       };
#       icon = "";
#     ...

{
  programs.nixvim.plugins.lualine = {
    enable = true;

    settings = {

      options = { globalstatus = true; };

      # +-------------------------------------------------+
      # | A | B | C                             X | Y | Z |
      # +-------------------------------------------------+
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [ "branch" ];
        lualine_c = [ "filename" "diff" ];

        lualine_x = [
          "diagnostics"

          # Show active language server
          {
            __raw = ''
              {
                function()
                  local msg = ""
                  local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
                  local clients = vim.lsp.get_active_clients()
                  if next(clients) == nil then
                      return msg
                  end
                  for _, client in ipairs(clients) do
                      local filetypes = client.config.filetypes
                      if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                          return client.name
                      end
                  end
                  return msg
                end,
                icon = "",
                color = { fg = "#ffffff" }
              }
            '';
          }
          # {
          #   name.__raw = ''
          #     function()
          #         local msg = ""
          #         local buf_ft = vim.api.nvim_buf_get_option(0, 'filetype')
          #         local clients = vim.lsp.get_active_clients()
          #         if next(clients) == nil then
          #             return msg
          #         end
          #         for _, client in ipairs(clients) do
          #             local filetypes = client.config.filetypes
          #             if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          #                 return client.name
          #             end
          #         end
          #         return msg
          #     end
          #   '';
          #   icon = "";
          #   color.fg = "#ffffff";
          # }
          "encoding"
          "fileformat"
          "filetype"
        ];
      };
    };
  };
}
