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
    # Coding agents and their companion tools, updated daily. Its own pinned
    # nixpkgs is kept so the prebuilt binaries in its cache match.
    llm-agents.url = "github:numtide/llm-agents.nix";
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

      # Exposed so the package can be built, and updated with nix-update, on its
      # own.
      packages.${system}.ovis = pkgs.callPackage ./pkgs/ovis.nix {
        # TODO: Use pkgs.bun once this nixpkgs has bun 1.4; the warning below
        # says when. Until then, Ovis's bun.lock needs a newer bun, taken from
        # the nixpkgs llm-agents pins.
        bun =
          pkgs.lib.warnIf (pkgs.lib.versionAtLeast pkgs.bun.version "1.4")
            "pkgs.bun is ${pkgs.bun.version}: build Ovis with it and drop the override in flake.nix"
            inputs.llm-agents.inputs.nixpkgs.legacyPackages.${system}.bun;
      };

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system} = {
        herdr-ovis = import ./tests/herdr-ovis.nix { inherit inputs pkgs; };
      };
    };
}
