{ pkgs, ... }:

let
  gstPlugins = with pkgs.gst_all_1; [
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
  ];
  gstPluginPath = pkgs.lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins;
  whisperingBin = "/home/hybridz/Projects/epicenter/apps/whispering/src-tauri/target/release/whispering";
  iconPath = "/home/hybridz/Projects/epicenter/apps/whispering/src-tauri/icons/128x128.png";
in
pkgs.symlinkJoin {
  name = "whispering";
  paths = [
    (pkgs.writeShellScriptBin "whispering" ''
      export GST_PLUGIN_PATH="${gstPluginPath}:''${GST_PLUGIN_PATH:-}"
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      export GDK_BACKEND=wayland
      exec ${whisperingBin} "$@"
    '')
    (pkgs.makeDesktopItem {
      name = "whispering";
      desktopName = "Whispering";
      comment = "Press shortcut → speak → get text. Free and open source";
      exec = "whispering";
      icon = iconPath;
      categories = [ "Office" ];
      startupWMClass = "whispering";
    })
  ];
}
