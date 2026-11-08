# Catppuccin Latte across the command-line tools. Tools that bundle the theme,
# such as herdr and hunk, name it in their own configuration instead.
{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "latte";
    # Without this, the theme would also reach any program enabled later,
    # without a change here to show it.
    autoEnable = false;
    fish.enable = true;
    fzf.enable = true;
    eza.enable = true;
    delta.enable = true;
    micro.enable = true;
    # Read by programs that render Markdown with glamour, such as gh.
    glamour.enable = true;
  };

  # glow reads GLAMOUR_STYLE only in its TUI. When it prints a file, it takes
  # the style from its configuration file.
  xdg.configFile."glow/glow.yml".source = (pkgs.formats.yaml { }).generate "glow-config" {
    style = config.home.sessionVariables.GLAMOUR_STYLE;
  };
}
