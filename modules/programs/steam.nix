# Steam Gaming Platform
# Includes gamescope and network features
{ ... }:

{
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    gamemode.enable = false;
  };
}
