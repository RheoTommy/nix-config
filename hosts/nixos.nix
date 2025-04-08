{ config, pkgs, lib, ... }:

{
  # NixOS-specific configurations
  
  # Enable integration with GNOME Keyring (if you use GNOME)
  # services.gnome-keyring.enable = true;
  
  # Enable integration with system themes
  gtk = {
    enable = true;
    # Uncomment and modify to match your system theme
    # theme = {
    #   name = "Adwaita";
    #   package = pkgs.gnome.adwaita-icon-theme;
    # };
  };
  
  # NixOS-specific packages
  home.packages = with pkgs; [
    # Add NixOS-specific packages here
    # For example, tools that integrate with the system
    xdg-utils
  ];
  
  # You can add more NixOS-specific configurations here
  
  # Example: Configure XDG directories
  xdg = {
    enable = true;
    # Uncomment and modify as needed
    # userDirs = {
    #   enable = true;
    #   desktop = "$HOME/Desktop";
    #   documents = "$HOME/Documents";
    #   download = "$HOME/Downloads";
    #   music = "$HOME/Music";
    #   pictures = "$HOME/Pictures";
    #   videos = "$HOME/Videos";
    # };
  };
}