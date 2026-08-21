# Defines the OS account and connects it to its Home Manager configuration.
{ pkgs, ... }:

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

  # Allow rheotommy to use 1Password features backed by polkit.
  programs._1password-gui.polkitPolicyOwners = [ "rheotommy" ];

  # Apply this user-scoped Home Manager module during the host NixOS activation.
  home-manager.users.rheotommy = import ../../../../home/rheotommy;
}
