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
        in
            {
                nixosConfigurations = {
                    virtualbox = inputs.nixpkgs.lib.nixosSystem {
                        system = system;
                        modules = [
                            ./hosts/virtualbox
                        ];
                    };
                };
            };
}