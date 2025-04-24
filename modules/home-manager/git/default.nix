{ ... }:

{
  # Git configuration (example, customize as needed)
  programs.git = {
    enable = true;
    userName = "rheotommy"; # Replace with your actual Git username
    userEmail = "tommyrheo@gmail.com"; # Replace with your actual Git email
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  programs.gh.enable = true;
}
