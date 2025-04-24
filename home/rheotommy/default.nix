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
    ../../modules/home-manager/git
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

  # --- Program Configurations ---

  # Git configuration (example, customize as needed)
  programs.git = {
    enable = true;
    userName = "rheotommy"; # Replace with your actual Git username
    userEmail = "tommyrheo@gmail.com"; # Replace with your actual Git email
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Starship prompt configuration (if used in user's shell)
  programs.starship = {
    enable = true;
    enableZshIntegration = true; # If using Zsh
    # settings = { ... }; # Custom starship settings
  };

  # Zsh configuration (if Zsh is the user's shell)
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
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

}
