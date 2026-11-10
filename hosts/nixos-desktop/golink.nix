# Runs golink, which joins the tailnet as the machine "go" and redirects
# go/<name> to the services this machine serves to the tailnet.
#
# On the first start, golink logs a login URL (`journalctl -u golink`); open
# it to add "go" to the tailnet. After that, disable its key expiry in the
# Tailscale admin console, or it drops off the tailnet when the key expires.
{ lib, pkgs, ... }:

let
  host = "https://nixos-desktop.tail5d70dc.ts.net";
  links = {
    ovis = host;
    gatus = "${host}:8443";
    ha = "${host}:8124";
  };
  snapshot = pkgs.writeText "golink-links.jsonl" (
    lib.concatMapStringsSep "\n" (
      short:
      builtins.toJSON {
        Short = short;
        Long = links.${short};
      }
    ) (lib.attrNames links)
  );
  # Not pkgs.golink as it is: nixpkgs pins a July 2026 commit that no longer
  # builds with the Go in nixpkgs from November 2026. Upstream updated its Go
  # dependencies on 2026-10-21; once nixpkgs ships that or later, this uses
  # pkgs.golink and warns.
  golink =
    if lib.versionAtLeast pkgs.golink.version "1.0.0-unstable-2026-10-21" then
      lib.warn "golink in nixpkgs is now ${pkgs.golink.version}: remove the override in hosts/nixos-desktop/golink.nix" pkgs.golink
    else
      pkgs.golink.overrideAttrs {
        version = "1.0.0-unstable-2026-10-27";
        src = pkgs.fetchFromGitHub {
          owner = "tailscale";
          repo = "golink";
          rev = "d02fb073fd1cb92f034aee40f1d3c6c846fecff1";
          hash = "sha256-C0lov54z1bhkylLn/PnGV7kA/wq2c0cb+F4x2ZAJdgI=";
        };
        vendorHash = "sha256-eOQSpWazd6OoGxIKRfdzt/BG8LfnOPBoj2nTQD+FhOk=";
      };
in
{
  systemd.services.golink = {
    description = "Serve go links to the tailnet";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "golink";
      Restart = "on-failure";
    };
    # golink loads a snapshot only into links that do not exist yet, so the
    # database starts empty each time to make the links exactly those above.
    # The tailnet identity in tsnet/ is kept.
    script = ''
      rm -f "$STATE_DIRECTORY"/links.db*
      exec ${lib.getExe golink} -readonly \
        -sqlitedb "$STATE_DIRECTORY/links.db" \
        -config-dir "$STATE_DIRECTORY/tsnet" \
        -snapshot ${snapshot}
    '';
  };
}
