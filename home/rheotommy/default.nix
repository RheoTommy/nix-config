# User-scoped packages and configuration managed by Home Manager.
{ ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./cli.nix
    ./agents.nix
    ./terminal.nix
    ./apps.nix
  ];

  home = {
    username = "rheotommy";
    homeDirectory = "/home/rheotommy";
    # Initial production baseline. Keep this value across future upgrades.
    stateVersion = "26.05";
  };
}
