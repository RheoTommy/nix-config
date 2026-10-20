# The terminal multiplexer that keeps agent sessions alive across disconnects.
{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr
  ];
  xdg.configFile."herdr/config.toml".source = ./config/herdr.toml;
}
