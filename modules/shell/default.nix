{ config, pkgs, lib, ... }:

{
  # Shell module - configurations for shells and terminal utilities
  
  # Import all enabled submodules
  imports = [
    # Uncomment as needed
    # ./zsh.nix
    # ./fish.nix
    # ./starship.nix
    # ./alacritty.nix
    # ./kitty.nix
  ];
  
  # Common shell packages
  home.packages = with pkgs; [
    # Terminal multiplexers
    tmux
    
    # Shell utilities
    fzf
    jq
    
    # Add more shell-related packages here
  ];
  
  # Example: Configure Starship prompt
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = true;
  #     character = {
  #       success_symbol = "[➜](bold green)";
  #       error_symbol = "[✗](bold red)";
  #     };
  #   };
  # };
  
  # Example: Configure ZSH
  # programs.zsh = {
  #   enable = true;
  #   autosuggestion.enable = true;
  #   syntaxHighlighting.enable = true;
  #   oh-my-zsh = {
  #     enable = true;
  #     plugins = [ "git" "docker" "sudo" ];
  #     theme = "robbyrussell";
  #   };
  # };
  
  # This is where you can add more shell configurations
}