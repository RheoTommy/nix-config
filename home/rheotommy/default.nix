{ inputs, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/common
    ../../modules/home-manager/programs/jujutsu
    ../../modules/home-manager/programs/zellij
  ];

  home = {
    username = "rheotommy";
    homeDirectory = "/home/rheotommy";
    stateVersion = "25.11";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "RheoTommy";
      email = "tommyrheo@gmail.com";
    };
  };

  home.packages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
