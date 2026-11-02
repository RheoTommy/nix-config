# General command-line tools used across projects.
{ pkgs, ... }:

{
  home.packages = [
    # Search and text processing
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.curl
    # Without NO_WORKING_ISPRINT, `unzip -l` and `unzip -Z1` print each
    # non-ASCII byte of a name as `?`. Debian and Ubuntu build with it:
    # https://bugs.launchpad.net/ubuntu/+source/unzip/+bug/1199239
    # Not an overlay, which would also rebuild every package that unpacks
    # its source with unzip.
    (pkgs.unzip.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = toString (old.NIX_CFLAGS_COMPILE or "") + " -DNO_WORKING_ISPRINT";
    }))

    # Editing and viewing
    pkgs.glow
    pkgs.poppler-utils
    pkgs.typst
    pkgs.wl-clipboard

    # Scripting
    pkgs.python3
    pkgs.uv

    pkgs.awscli2
  ];

  xdg.configFile."glow/glow.yml".source = (pkgs.formats.yaml { }).generate "glow-config" {
    style = "light";
  };

  programs.micro = {
    enable = true;
    settings.colorscheme = "simple";
    # OSC 52, so that copying works through herdr and SSH too.
    settings.clipboard = "terminal";
  };

  # The default browser flow needs a browser on this machine. A device code can
  # be approved from any other device, such as over SSH or from a phone.
  programs.fish.shellAbbrs.awslogin = "aws sso login --use-device-code";
}
