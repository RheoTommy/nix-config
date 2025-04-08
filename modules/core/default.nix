{ config, pkgs, lib, ... }:

{
  # Core module - essential configurations for all environments
  
  # Import all enabled submodules
  imports = [
    # Uncomment as needed
    # ./git.nix
    # ./ssh.nix
    # ./tmux.nix
  ];
  
  # Basic shell aliases
  home.shellAliases = {
    ll = "ls -la";
    ".." = "cd ..";
    "..." = "cd ../..";
    "grep" = "grep --color=auto";
  };
  
  # Default file permissions
  home.file = {
    # Example: Set executable permissions for scripts in ~/bin
    # "${config.home.homeDirectory}/bin" = {
    #   source = ./bin;
    #   recursive = true;
    #   executable = true;
    # };
  };
  
  # Core programs that should be available everywhere
  programs = {
    # Enable bash configuration
    bash = {
      enable = true;
      historyControl = ["ignoredups" "ignorespace"];
      historySize = 10000;
    };
    
    # Enable direnv for environment management
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  
  # This is where you can add more core configurations
  # that should be available in all environments
}