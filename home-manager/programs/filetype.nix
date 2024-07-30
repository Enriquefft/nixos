{ pkgs, ... }: {
  programs.nixvim.filetype = {

    extension = { rasi = "rasi"; };
    pattern = {
      ".*/waybar/config" = "jsonc";
      ".*/mako/config" = "dosini";
      ".*/kitty/*.conf" = "bash";
      ".*/hypr/.*%.conf" = "hyprlang";
    };
  };
}
