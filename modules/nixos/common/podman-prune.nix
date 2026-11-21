# Removes the Podman images that builds have stopped using, daily.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Not virtualisation.podman.autoPrune: it runs as root and leaves each user's
  # rootless images alone.
  systemd.user.services.podman-prune = {
    description = "Prune Podman images that no build has used for three days";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe (
        pkgs.writeShellApplication {
          name = "podman-prune";
          runtimeInputs = [
            config.virtualisation.podman.package
            pkgs.findutils
            pkgs.jq
          ];
          text = builtins.readFile ./podman-prune.sh;
        }
      );
      IOSchedulingClass = "idle";
    };
    startAt = "daily";
  };
  systemd.user.timers.podman-prune.timerConfig.Persistent = true;
}
