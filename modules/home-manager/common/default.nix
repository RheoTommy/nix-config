{ ... }:

{
  # This only installs the `home-manager` CLI into the user environment. The
  # NixOS integration is configured in `modules/nixos/home-manager-integration`.
  programs.home-manager.enable = true;
}
