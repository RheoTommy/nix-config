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
    # Declarative disk partitioning, used both at install time and to generate
    # the fileSystems entries.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secure Boot signing for systemd-boot and the kernel images. Upstream
    # recommends tracking a release tag rather than main.
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
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
