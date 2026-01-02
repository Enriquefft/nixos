# Firefox Browser
# System-level configuration
{ ... }:

{
  programs.firefox = {
    enable = true;
    preferences = {
      "browser.fullscreen.autohide" = false;
    };
  };
}
