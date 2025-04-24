{ pkgs, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      cat = "bat";
      grep = "rg";
      ls = "eza --icons always --classify always";
      la = "eza --icons always --classify always --all ";
      ll = "eza --icons always --long --all --git ";
      tree = "eza --icons always --classify always --tree";
    };
  };

  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    actionlint
    delta
    fd
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
