# The terminal multiplexer that keeps agent sessions alive across disconnects,
# run as a user service together with Ovis, its web UI.
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
  home.packages = [ herdr ];
  xdg.configFile."herdr/config.toml".source = ./config/herdr.toml;

  # The server of the default session. Linger starts it at boot, so sessions
  # come back after a reboot without a login.
  systemd.user.services.herdr = {
    Unit = {
      Description = "herdr server";
      # Stopping the server kills every pane and the agents in them. Keep a
      # running server across switches; restart it by hand at a good moment.
      X-RestartIfChanged = false;
    };
    Service = {
      # A server started by hand may already own the socket. A second server
      # would exit with an error and be restarted in a loop; skip it instead.
      ExecCondition = pkgs.writeShellScript "herdr-not-running" ''
        [ "$(${lib.getExe herdr} status server --json | ${lib.getExe pkgs.jq} -r .running)" != true ]
      '';
      ExecStart = "${lib.getExe herdr} server";
      WorkingDirectory = "%h";
      # The manager's environment may come from a desktop session that
      # already sourced the NixOS environment and marked it done. Clear the
      # mark, so the fish in each pane sources it again and picks up session
      # variables, such as DOCKER_HOST, set after that session started.
      UnsetEnvironment = [ "__NIXOS_SET_ENVIRONMENT_DONE" ];
      # Signal only herdr itself. On SIGTERM it saves the session layout and
      # hangs up its panes, as closing a terminal does.
      KillMode = "mixed";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Ovis, reachable only from this machine. The tailnet reaches it through
  # `tailscale serve`, set up by the remote-access NixOS module.
  systemd.user.services.ovis = {
    Unit = {
      Description = "Ovis, the web UI for herdr";
      # Requires rather than BindsTo: Ovis reconnects on its own when herdr
      # restarts after a crash, and it keeps serving a server started by hand,
      # which makes herdr.service skip its start.
      Requires = [ "herdr.service" ];
      After = [ "herdr.service" ];
    };
    Service = {
      ExecStart = lib.getExe ovis;
      Environment = [
        "HOST=127.0.0.1"
        "PORT=7317"
        "HERDR_SOCKET=%h/.config/herdr/herdr.sock"
        # Attach to panes with the same herdr as the server.
        "HERDR_WEB_HERDR_BIN=${lib.getExe herdr}"
        # Shown in Settings as the port to serve the app on.
        "HERDR_WEB_TAILSCALE_HTTPS_PORT=443"
        "HERDR_WEB_STATE_DIR=%S/ovis"
        "HERDR_WEB_TELEMETRY=0"
        # Updates come from this repository. Ovis run directly, outside its
        # supervisor, cannot update itself anyway; keep it off explicitly.
        "HERDR_WEB_AUTO_UPDATE=0"
      ];
      StateDirectory = "ovis";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
