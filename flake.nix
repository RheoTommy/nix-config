{
    description = "NixOS configuration";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, home-manager, ... }@inputs:
        let
            system = "x86_64-linux";
            username = "rheotommy";

            hostsDir = (builtins.readDir ./hosts);
            hosts = builtins.filter (name: hostsDir.${name} == "directory") (builtins.attrNames hostsDir);
            mkNixosSystem = hostName: inputs.nixpkgs.lib.nixosSystem {
                inherit system;
                modules = [
                    ./hosts/${hostName}
                ];
                specialArgs = { inherit username hostName inputs; };
            };
        in
            {
                nixosConfigurations = builtins.listToAttrs (builtins.map (hostName: {
                    name = hostName;
                    value = mkNixosSystem hostName;
                }) hosts);
            };
}