{
  description = "Home Manager configuration";

  inputs = {
    # Specify the sources of Home Manager and Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # Helper function to create system-specific configurations
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper function to create a home-manager configuration for a specific system
      mkHomeConfiguration = { system, username, homeDirectory, extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit inputs;
            inherit username;
          };
          modules = [
            # Base configuration
            ./home/default.nix
            
            # User-specific configuration
            {
              home = {
                inherit username homeDirectory;
                stateVersion = "23.11"; # Adjust as needed
              };
            }
          ] ++ extraModules;
        };
    in
    {
      # Home Manager configurations accessible via 'home-manager switch --flake .#username@hostname'
      homeConfigurations = {
        # Example configuration - modify or add more as needed
        "example@nixos" = mkHomeConfiguration {
          system = "x86_64-linux";
          username = "example";
          homeDirectory = "/home/example";
          extraModules = [
            ./hosts/nixos.nix
          ];
        };
        
        # You can add more configurations for different users/systems here
      };

      # This makes the configuration accessible as a NixOS module
      nixosModules.default = { ... }: {
        imports = [ ./modules ];
      };

      # Provide a development shell for working with this configuration
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              home-manager
              git
              nixpkgs-fmt
            ];
          };
        }
      );
    };
}