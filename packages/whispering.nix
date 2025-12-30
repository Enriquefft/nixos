{ pkgs, ... }:

pkgs.writeShellScriptBin "whispering" ''
  exec /home/hybridz/Projects/epicenter/apps/whispering/src-tauri/target/release/whispering "$@"
''
