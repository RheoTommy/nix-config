{
  config,
  pkgs,
  inputs,
  qqqlib,
  username,
  ...
}:

{
  imports = [
    ../../modules/home-manager/apps
    ../../modules/home-manager/browser
    ../../modules/home-manager/git
    ../../modules/home-manager/vscode
    ../../modules/home-manager/zsh
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # Set state version for compatibility. Do not change unless necessary.
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME/Public";
    templates = "$HOME/Templates";
    videos = "$HOME/Videos";
  };

  # Packages installed for this user only
  home.packages = with pkgs; [
    vscode # Visual Studio Code
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

  # VSCode configuration (example)
  # programs.vscode = {
  #   enable = true;
  #   # extensions = with pkgs.vscode-extensions; [ ... ];
  #   # userSettings = { ... };
  # };

}
