# The interactive fish shell and the tools that hook into it.
{ lib, pkgs, ... }:

{
  # The login shell itself is set by NixOS. Enabling it here as well lets the
  # Home Manager modules below add their fish integration.
  programs.fish = {
    enable = true;
    shellAliases.clip = "wl-copy";
  };

  programs.starship = {
    enable = true;
    # The catppuccin-powerline preset that ships with starship, in the light
    # latte flavor to match the terminal theme.
    settings =
      lib.recursiveUpdate
        (builtins.fromTOML (
          builtins.readFile "${pkgs.starship}/share/starship/presets/catppuccin-powerline.toml"
        ))
        {
          palette = "catppuccin_latte";
          # The preset has no NixOS icon, so starship would fall back to an
          # emoji whose width varies between terminals and breaks the prompt.
          os.symbols.NixOS = "";
        };
  };

  # Ctrl-R searches history, Ctrl-T inserts a path, and Alt-C changes directory.
  programs.fzf = {
    enable = true;
    # fzf assumes a dark background by default. These are catppuccin latte
    # colors; the background is left to the terminal.
    colors = {
      "bg+" = "#ccd0da";
      fg = "#4c4f69";
      "fg+" = "#4c4f69";
      hl = "#d20f39";
      "hl+" = "#d20f39";
      header = "#d20f39";
      info = "#8839ef";
      prompt = "#8839ef";
      pointer = "#dc8a78";
      marker = "#7287fd";
      spinner = "#dc8a78";
      border = "#9ca0b0";
    };
  };

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
