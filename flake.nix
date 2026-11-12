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
    # Marks herdr agent panes that need action. It takes herdr for its
    # integration check from llm-agents, as we do, so that the check runs the
    # herdr installed here.
    herdr-needs-action = {
      url = "github:RheoTommy/herdr-needs-action";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.herdr-pkgs.follows = "llm-agents";
    };
    # Catppuccin themes for the tools that do not bundle them. main, not a
    # release branch: the release branches target stable NixOS.
    catppuccin = {
      url = "github:catppuccin/nix";
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

      # Exposed so the package can be built, and updated with nix-update, on its
      # own.
      packages.${system}.ovis = pkgs.callPackage ./pkgs/ovis.nix { };

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system} = {
        envfs-statfs = import ./tests/envfs-statfs.nix { inherit pkgs; };
        herdr-ovis = import ./tests/herdr-ovis.nix { inherit inputs pkgs; };
        job-alerts = import ./tests/job-alerts.nix { inherit pkgs; };
        op-secrets = import ./tests/op-secrets.nix { inherit pkgs; };
        podman-prune = import ./tests/podman-prune.nix { inherit pkgs; };
        podman-registries = import ./tests/podman-registries.nix { inherit pkgs; };
        scheduled-jobs = import ./tests/scheduled-jobs.nix { inherit pkgs; };
        herdr-needs-action = inputs.herdr-needs-action.checks.${system}.integration;
        # A copy, since treefmt rewrites files in place and the source is
        # read-only.
        formatting = pkgs.runCommand "formatting" { nativeBuildInputs = [ pkgs.nixfmt-tree ]; } ''
          cp -R ${./.} src
          chmod -R u+w src
          treefmt --ci --tree-root src
          touch $out
        '';
      };
    };
}
