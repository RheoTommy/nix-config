{ config, pkgs, inputs, lib, username, ... }:

{
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    programs.home-manager.enable = true;

    # Packages installed for this user only
    packages = with pkgs; [
      vscode # Visual Studio Code
      eza # Modern replacement for 'ls'

      # Add other user-specific packages here
      # Example:
      # neovim
      # tmux
      # htop
    ];

    # Environment variables for the user session
    # sessionVariables = {
    #   EDITOR = "vim";
    # };

    # Aliases for the user's shell
    # shellAliases = {
    #   ll = "eza -l";
    #   la = "eza -la";
    # };
  };

  # --- Program Configurations ---

  # Git configuration (example, customize as needed)
  programs.git = {
    enable = true;
    userName = "rheotommy"; # Replace with your actual Git username
    userEmail = "your.email@example.com"; # Replace with your actual Git email
    # extraConfig = {
    #   init.defaultBranch = "main";
    # };
  };

  # Starship prompt configuration (if used in user's shell)
  programs.starship = {
    enable = true;
    # enableZshIntegration = true; # If using Zsh
    # settings = { ... }; # Custom starship settings
  };

  # Zsh configuration (if Zsh is the user's shell)
  programs.zsh = {
    enable = true;
    # enableAutosuggestions = true;
    # enableCompletion = true;
    # syntaxHighlighting.enable = true;
    # oh-my-zsh = {
    #   enable = true;
    #   plugins = [ "git" ];
    #   theme = "robbyrussell";
    # };
    # initExtra = ''
    #   # Custom Zsh settings
    #   bindkey -e
    # '';
  };

  # VSCode configuration (example)
  # programs.vscode = {
  #   enable = true;
  #   # extensions = with pkgs.vscode-extensions; [ ... ];
  #   # userSettings = { ... };
  # };

  # --- Home Manager Service ---
  # This line is managed by the NixOS module, so it's not strictly needed here.
  # programs.home-manager.enable = true;

  # --- Import common modules (when you create them) ---
  # imports = [
  #   ../../modules/home-manager/base.nix
  #   ../../modules/home-manager/cli-tools.nix
  # ];

  # Set state version for compatibility. Do not change unless necessary.
  stateVersion = "24.11";
}
