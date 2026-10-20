# Desktop applications. Only the packages are installed; their settings stay
# unmanaged.
{ pkgs, ... }:

{
  home.packages = [
    pkgs.slack
    pkgs.discord
    pkgs.spotify
    pkgs.teams-for-linux
    pkgs.zoom-us
    pkgs.vscode
  ];
}
