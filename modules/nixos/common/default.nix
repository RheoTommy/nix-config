# Aggregates the reusable NixOS baseline shared by every imported host.
{ ... }:

{
  imports = [
    ./nix.nix
    ./envfs.nix
    ./system.nix
    ./tailscale.nix
    ./desktop.nix
    ./podman.nix
    ./podman-prune.nix
    ./users/rheotommy.nix
  ];
}
