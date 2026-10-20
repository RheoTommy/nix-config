# The interactive fish shell and the tools that hook into it.
{ pkgs, ... }:

{
  # The login shell itself is set by NixOS. Enabling it here as well lets the
  # Home Manager modules below add their fish integration.
  programs.fish = {
    enable = true;
    shellAliases.clip = "wl-copy";
  };

  programs.starship = {
    enable = true;
    # The gruvbox-rainbow preset that ships with starship.
    settings = builtins.fromTOML (
      builtins.readFile "${pkgs.starship}/share/starship/presets/gruvbox-rainbow.toml"
    );
  };

  # Ctrl-R searches history, Ctrl-T inserts a path, and Alt-C changes directory.
  programs.fzf.enable = true;

  # Replaces ls with eza, which adds icons and each file's git status.
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  # Loads a project's .envrc on entering its directory. nix-direnv caches
  # `use flake` environments so entering them stays fast.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Runtimes for existing projects come from each project's mise.toml. No
  # global tool versions are declared here.
  programs.mise = {
    enable = true;
    globalConfig.settings = {
      # Use prebuilt runtimes. NixOS lacks the headers and libraries a source
      # build expects, while nix-ld lets the prebuilt binaries run.
      all_compile = false;
      python.compile = false;
    };
  };

  home.sessionVariables.EDITOR = "micro";
}
