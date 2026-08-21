# User-scoped packages and configuration managed by Home Manager.
{ pkgs, ... }:

{
  home = {
    username = "rheotommy";
    homeDirectory = "/home/rheotommy";
    # Initial production baseline. Keep this value across future upgrades.
    stateVersion = "26.05";
  };

  # Home Manager program modules both install the program and manage its
  # user-level configuration.
  programs.git = {
    enable = true;
    settings.user = {
      name = "RheoTommy";
      email = "tommyrheo@gmail.com";
    };
  };
  programs.gh.enable = true;

  # home.packages only installs these user-owned applications; their settings
  # remain unmanaged unless a dedicated Home Manager program module is added.
  home.packages = [
    pkgs.google-chrome
    pkgs.slack
    pkgs.discord
    pkgs.spotify
    pkgs.obsidian
    pkgs.teams-for-linux
    pkgs.zoom-us
  ];
}
