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
    # Initial production baseline. Keep this value across future upgrades.
    stateVersion = "26.05";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "RheoTommy";
      email = "tommyrheo@gmail.com";
    };
  };

  programs.gh.enable = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    history = {
      path = "$HOME/.histfile";
      size = 1000;
      save = 1000;
    };
    defaultKeymap = "emacs";
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default

    pkgs.mise
    pkgs.awscli2
    pkgs.google-cloud-sdk
    pkgs.xwayland-satellite
    pkgs.fuzzel
    pkgs.alacritty
    pkgs.waybar
    pkgs.mako
    pkgs.swaybg
    pkgs.swayidle
    pkgs.swaylock
    pkgs.wl-clipboard
    pkgs.grim
    pkgs.slurp

    pkgs.slack
    pkgs.discord
    pkgs.vscode
    pkgs.zed-editor
    pkgs.spotify
    pkgs.obsidian
    pkgs.teams-for-linux
    pkgs.zoom-us

    pkgs.jetbrains-toolbox
    pkgs.jetbrains.idea
    pkgs.jetbrains.goland
    pkgs.jetbrains.rust-rover
    pkgs.jetbrains.clion
    pkgs.jetbrains.webstorm
    pkgs.jetbrains.pycharm
  ];
}
