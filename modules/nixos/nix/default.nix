{ lib, ... }:

{
  # Enable unfree software
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  nix = {
    settings = {
      auto-optimise-store = lib.mkDefault true;
      experimental-features = lib.mkDefault [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };
}
