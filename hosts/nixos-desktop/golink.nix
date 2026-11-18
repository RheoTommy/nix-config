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
      exec ${lib.getExe pkgs.golink} -readonly \
        -sqlitedb "$STATE_DIRECTORY/links.db" \
        -config-dir "$STATE_DIRECTORY/tsnet" \
        -snapshot ${snapshot}
    '';
  };
}
