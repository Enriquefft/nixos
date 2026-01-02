# Input Services
# Keyboard remapping with keyd
{ ... }:

{
  services.keyd = {
    enable = true;

    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "esc";
            escape = "capslock";
            f5 = "2";
          };
        };
      };
    };
  };
}
