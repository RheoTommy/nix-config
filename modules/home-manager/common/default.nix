{ config, ... }:

{
  # In the NixOS module integration, Home Manager activation is driven by
  # `nixos-rebuild`, not by the CLI. The CLI is still useful for inspecting
  # generations, so install it explicitly.
  programs.home-manager.enable = true;
  home.packages = [
    config.programs.home-manager.package
  ];
}
