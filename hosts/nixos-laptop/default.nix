# Machine-specific configuration for the ThinkPad T14s Gen 3 (AMD) laptop. It
# is a client of the desktop: agents and long-running work stay there.
{ ... }:

{
  imports = [
    ../../modules/nixos/common
    ../../modules/nixos/home-manager-integration
    ../../modules/nixos/plasma
    ../../modules/nixos/secure-boot
    ./disko.nix
    ./hardware-configuration.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-laptop";

  # Initial production baseline. Keep this value across future upgrades.
  system.stateVersion = "26.11";
}
