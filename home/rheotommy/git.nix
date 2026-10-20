# Version control: git, jj, GitHub, and the ghq repository layout.
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Reo Hitomi";
        email = "tommyrheo@gmail.com";
      };
      init.defaultBranch = "main";
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      light = true;
      line-numbers = true;
    };
  };

  programs.jujutsu = {
    enable = true;
    settings.user = config.programs.git.settings.user;
  };

  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-stack ];
  };

  # `ghq get` clones into ~/ghq/<host>/<owner>/<repo>. Ctrl-G picks a
  # repository there with fzf and changes into it.
  home.packages = [ pkgs.ghq ];
  programs.fish = {
    functions.ghq_fzf_cd = ''
      set -l dir (ghq list --full-path | fzf --scheme=path)
      and cd $dir
      commandline -f repaint
    '';
    interactiveShellInit = ''
      bind ctrl-g ghq_fzf_cd
    '';
  };
}
