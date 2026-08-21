# Aggregates the reusable NixOS baseline shared by every imported host.
{ ... }:

{
  imports = [
    ./nix.nix
    ./system.nix
    ./desktop.nix
    ./podman.nix
    ./users/rheotommy.nix
  ];
}
