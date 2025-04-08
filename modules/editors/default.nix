{ config, pkgs, lib, ... }:

{
  # Editors module - configurations for text editors and IDEs
  
  # Import all enabled submodules
  imports = [
    # Uncomment as needed
    # ./vim.nix
    # ./neovim.nix
    # ./emacs.nix
    # ./vscode.nix
  ];
  
  # Common editor packages
  home.packages = with pkgs; [
    # Command-line editors
    nano
    
    # Add more editor-related packages here
  ];
  
  # Example: Configure Neovim
  # programs.neovim = {
  #   enable = true;
  #   viAlias = true;
  #   vimAlias = true;
  #   extraConfig = ''
  #     set number
  #     set relativenumber
  #     set expandtab
  #     set tabstop=2
  #     set shiftwidth=2
  #   '';
  #   plugins = with pkgs.vimPlugins; [
  #     vim-nix
  #     vim-commentary
  #     vim-surround
  #   ];
  # };
  
  # Example: Configure VS Code
  # programs.vscode = {
  #   enable = true;
  #   extensions = with pkgs.vscode-extensions; [
  #     vscodevim.vim
  #     ms-python.python
  #     jnoortheen.nix-ide
  #   ];
  #   userSettings = {
  #     "editor.fontSize" = 14;
  #     "editor.fontFamily" = "Fira Code, monospace";
  #     "editor.fontLigatures" = true;
  #   };
  # };
  
  # This is where you can add more editor configurations
}