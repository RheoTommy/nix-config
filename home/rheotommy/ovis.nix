# Ovis, the web UI for the herdr server from terminal.nix. Imported by the
# remote-access module, which serves it to the tailnet.
{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  herdr = inputs.llm-agents.packages.${system}.herdr;
  ovis = inputs.self.packages.${system}.ovis;
in
{
  systemd.user.services.ovis = {
    Unit = {
      Description = "Ovis, the web UI for herdr";
      # Not BindsTo: Ovis must keep serving a server started by hand, which
      # makes herdr.service skip its start.
      Requires = [ "herdr.service" ];
      After = [ "herdr.service" ];
    };
    Service = {
      ExecStart = lib.getExe ovis;
      Environment = [
        "HOST=127.0.0.1"
        "PORT=7317"
        "HERDR_SOCKET=%h/.config/herdr/herdr.sock"
        "OVIS_HERDR_BIN=${lib.getExe herdr}"
        # The port tailscale-serve-ovis serves on.
        "OVIS_TAILSCALE_HTTPS_PORT=443"
        "OVIS_STATE_DIR=%S/ovis"
        "OVIS_TELEMETRY=0"
        "OVIS_AUTO_UPDATE=0"
      ];
      StateDirectory = "ovis";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
