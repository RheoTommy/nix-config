# Configures Nix itself and repository-wide nixpkgs policy.
{ ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  nixpkgs.config.allowUnfree = true;

  # NixOS has no /lib64/ld-linux-x86-64.so.2, so pre-built binaries that were
  # not packaged with Nix (mise-installed runtimes, npm-downloaded helpers,
  # vendor CLIs) fail to start. nix-ld provides that loader path together with
  # a baseline set of shared libraries.
  programs.nix-ld.enable = true;
}
