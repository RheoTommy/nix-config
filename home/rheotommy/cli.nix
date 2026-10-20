# General command-line tools used across projects.
{ pkgs, ... }:

{
  home.packages = [
    # Search and text processing
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.curl
    pkgs.unzip

    # Editing and viewing
    pkgs.micro
    pkgs.glow
    pkgs.poppler-utils
    pkgs.typst
    pkgs.wl-clipboard

    # Scripting
    pkgs.python3
    pkgs.uv

    pkgs.awscli2
  ];
}
