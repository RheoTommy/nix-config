{ config, pkgs, lib, ... }:

{
  # Desktop module - configurations for desktop environments and GUI applications
  
  # Import all enabled submodules
  imports = [
    # Uncomment as needed
    # ./i3.nix
    # ./sway.nix
    # ./gnome.nix
    # ./kde.nix
    # ./xfce.nix
    # ./fonts.nix
    # ./firefox.nix
    # ./chromium.nix
  ];
  
  # Common desktop packages
  home.packages = with pkgs; [
    # GUI utilities
    pavucontrol
    
    # Image viewers and editors
    feh
    
    # Add more desktop-related packages here
  ];
  
  # Example: Configure fonts
  # fonts.fontconfig.enable = true;
  
  # Example: Configure Firefox
  # programs.firefox = {
  #   enable = true;
  #   profiles = {
  #     default = {
  #       id = 0;
  #       settings = {
  #         "browser.startup.homepage" = "https://nixos.org";
  #         "browser.search.region" = "US";
  #         "browser.search.isUS" = true;
  #         "browser.ctrlTab.recentlyUsedOrder" = false;
  #       };
  #       extensions = with pkgs.nur.repos.rycee.firefox-addons; [
  #         ublock-origin
  #         darkreader
  #       ];
  #     };
  #   };
  # };
  
  # Example: Configure i3 window manager
  # xsession.windowManager.i3 = {
  #   enable = true;
  #   config = {
  #     modifier = "Mod4";
  #     terminal = "alacritty";
  #     menu = "rofi -show drun";
  #   };
  # };
  
  # This is where you can add more desktop configurations
}