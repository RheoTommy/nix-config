{
  description = "RheoTommy NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      nixosDesktop = nixpkgs.lib.nixosSystem {
        inherit system;
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
