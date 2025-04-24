{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "rheotommy";

      hostsDir = (builtins.readDir ./hosts);
      hosts = builtins.filter (name: hostsDir.${name} == "directory") (builtins.attrNames hostsDir);
      mkNixosSystem =
        hostName:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${hostName}

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."${username}" = ./home/${username};
              home-manager.extraSpecialArgs = { inherit username inputs; };
            }
          ];
          specialArgs = { inherit username hostName inputs; };
        };
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        builtins.map (hostName: {
          name = hostName;
          value = mkNixosSystem hostName;
        }) hosts
      );

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
