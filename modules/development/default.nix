{ config, pkgs, lib, ... }:

{
  # Development module - configurations for development environments and tools
  
  # Import all enabled submodules
  imports = [
    # Uncomment as needed
    # ./python.nix
    # ./node.nix
    # ./rust.nix
    # ./go.nix
    # ./java.nix
    # ./docker.nix
    # ./kubernetes.nix
  ];
  
  # Common development packages
  home.packages = with pkgs; [
    # Version control
    git
    
    # Build tools
    gnumake
    
    # Documentation
    man-pages
    
    # Add more development-related packages here
  ];
  
  # Example: Configure Git
  # programs.git = {
  #   enable = true;
  #   userName = "Your Name";
  #   userEmail = "your.email@example.com";
  #   extraConfig = {
  #     init.defaultBranch = "main";
  #     pull.rebase = true;
  #     push.autoSetupRemote = true;
  #   };
  # };
  
  # Example: Configure Python development environment
  # home.packages = with pkgs; [
  #   python3
  #   python3Packages.pip
  #   python3Packages.virtualenv
  #   python3Packages.black
  #   python3Packages.flake8
  #   python3Packages.pytest
  # ];
  
  # Example: Configure Node.js development environment
  # home.packages = with pkgs; [
  #   nodejs
  #   yarn
  #   nodePackages.npm
  #   nodePackages.typescript
  #   nodePackages.eslint
  # ];
  
  # This is where you can add more development configurations
}