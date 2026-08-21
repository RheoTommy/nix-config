# Defines flake inputs and assembles the NixOS configuration for each host.
{
  description = "RheoTommy NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      # Evaluate Home Manager with the same nixpkgs revision as NixOS.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nixosDesktop = nixpkgs.lib.nixosSystem {
        inherit system;
        # Expose flake inputs to NixOS modules; the Home Manager integration
        # module uses this to import its NixOS module.
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./hosts/nixos-desktop
        ];
      };
    in
    {
      nixosConfigurations = {
        nixos-desktop = nixosDesktop;
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
