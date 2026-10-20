# Configures Nix itself and repository-wide nixpkgs policy.
{ pkgs, ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Prebuilt binaries for the llm-agents.nix flake input.
  nix.settings.extra-substituters = [ "https://cache.numtide.com" ];
  nix.settings.extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];

  # A nixos-rebuild front end that shows build progress and the package diff
  # before switching.
  programs.nh.enable = true;

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
  # Libraries for the Chromium that Playwright downloads for browser tests.
  programs.nix-ld.libraries = [
    pkgs.alsa-lib
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
    pkgs.cairo
    pkgs.cups
    pkgs.dbus
    pkgs.expat
    pkgs.glib
    pkgs.libdrm
    pkgs.libgbm
    pkgs.libxkbcommon
    pkgs.nspr
    pkgs.nss
    pkgs.pango
    pkgs.systemd
    pkgs.libx11
    pkgs.libxcb
    pkgs.libxcomposite
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxrandr
  ];
}
