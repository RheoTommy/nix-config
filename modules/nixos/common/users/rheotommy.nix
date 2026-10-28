# Defines the OS account and connects it to its Home Manager configuration.
{ lib, pkgs, ... }:

{
  users.users.rheotommy = {
    isNormalUser = true;
    description = "rheotommy";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.fish.enable = true;
  # Drop the default aliases that fish picks up from NixOS, so that the eza
  # aliases from Home Manager are the only ones.
  environment.shellAliases = lib.mkForce { };

  # Allow rheotommy to use 1Password features backed by polkit.
  programs._1password-gui.polkitPolicyOwners = [ "rheotommy" ];

  # Apply this user-scoped Home Manager module during the host NixOS activation.
  home-manager.users.rheotommy = import ../../../../home/rheotommy;
}
