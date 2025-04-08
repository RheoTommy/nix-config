{ config, pkgs, lib, inputs, username, ... }:

{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic home configuration
  home = {
    # Basic packages that should be available on all systems
    packages = with pkgs; [
      # Command line utilities
      bat
      fd
      ripgrep
      tree
      htop
      
      # Development tools
      git
      
      # Add more packages here as needed
    ];
    
    # Environment variables to set
    sessionVariables = {
      EDITOR = "nano";  # Change to your preferred editor
    };
  };

  # Import all enabled modules
  imports = [
    # Core modules
    ../modules/core
    
    # Optional modules - uncomment as needed
    # ../modules/shell
    # ../modules/editors
    # ../modules/desktop
    # ../modules/development
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion is set in the flake.nix file
}