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
      # `ghq get <repo>` without an owner falls back to $USER, which is
      # lowercase and would clone into ~/ghq/github.com/rheotommy.
      ghq.user = "RheoTommy";
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

  # Ctrl-G combines ghq repositories and gwq worktrees so navigation does
  # not depend on the current checkout.
  #
  # gwq creates and switches git worktrees, laid out like ghq under
  # ~/worktrees/<host>/<owner>/<repo>/<branch>. Per-repository setup, such as
  # files to copy into a new worktree, lives in each checkout's .gwq.toml.
  home.packages = [
    pkgs.ghq
    pkgs.gwq
  ];
  xdg.configFile."gwq/config.toml".source = (pkgs.formats.toml { }).generate "gwq-config" {
    # `gwq cd` and `gwq add -s` change the current shell's directory through
    # the fish integration below, instead of starting a nested shell.
    cd.launch_shell = false;
  };
  programs.fish = {
    functions.ghq_fzf_cd = ''
      set -l dir (
        begin
          ghq list --full-path
          gwq list --global --json | jq -r '.[].path'
        end | sort -u | fzf --scheme=path --no-multi
      )
      and cd -- "$dir"
      commandline -f repaint
    '';
    interactiveShellInit = ''
      bind ctrl-g ghq_fzf_cd
      gwq completion fish | source
    '';
  };
}
