# The terminal multiplexer that keeps agent sessions alive across disconnects,
# and Ovis, its web UI.
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

  systemd.user.services.herdr = {
    Unit = {
      Description = "herdr server";
      # Not restarted on switch: a restart kills every pane and its agent.
      X-RestartIfChanged = false;
    };
    Service = {
      # Skip rather than fail when a server started by hand owns the socket;
      # a failing start would be restarted in a loop.
      ExecCondition = pkgs.writeShellScript "herdr-not-running" ''
        [ "$(${lib.getExe herdr} status server --json | ${lib.getExe pkgs.jq} -r .running)" != true ]
      '';
      ExecStart = "${lib.getExe herdr} server";
      WorkingDirectory = "%h";
      # The marks come from the desktop session. Left set, fish in the panes
      # skips the NixOS environment and misses variables such as DOCKER_HOST.
      UnsetEnvironment = [
        "__NIXOS_SET_ENVIRONMENT_DONE"
        "__fish_nixos_env_preinit_sourced"
      ];
      # Not control-group: herdr saves the layout on SIGTERM before it hangs
      # up the panes itself.
      KillMode = "mixed";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };

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
        "HERDR_WEB_HERDR_BIN=${lib.getExe herdr}"
        # The port tailscale-serve-ovis serves on.
        "HERDR_WEB_TAILSCALE_HTTPS_PORT=443"
        "HERDR_WEB_STATE_DIR=%S/ovis"
        "HERDR_WEB_TELEMETRY=0"
        "HERDR_WEB_AUTO_UPDATE=0"
      ];
      StateDirectory = "ovis";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
