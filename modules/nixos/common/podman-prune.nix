# Removes the Podman images that builds have stopped using, daily, for the
# users named here.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.podmanPrune;
in
{
  options.podmanPrune.users = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "alice" ];
    description = ''
      The users whose rootless images are pruned. A run starts the user's
      systemd manager, and with it their services, if it is not running.
    '';
  };

  config = {
    # Not virtualisation.podman.autoPrune: it runs as root and leaves each
    # user's rootless images alone.
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
    };

    # A system unit starts the user's prune and ends with its result, so that
    # what watches system units, such as the job alerts, sees a failure. Not a
    # timer in the user's manager: nothing outside it learns how a run ended.
    # Not a system unit that runs the script as the user either: outside the
    # user's session Podman finds no runtime directory. It then fails, or
    # settles on one under /tmp, which that user's Podman keeps from then on.
    systemd.services = lib.listToAttrs (
      map (
        user:
        lib.nameValuePair "podman-prune-${user}" {
          description = "Prune ${user}'s Podman images";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe' config.systemd.package "systemctl"} --user --machine=${user}@ start podman-prune.service";
          };
          startAt = "daily";
        }
      ) cfg.users
    );
    systemd.timers = lib.listToAttrs (
      map (user: lib.nameValuePair "podman-prune-${user}" { timerConfig.Persistent = true; }) cfg.users
    );
  };
}
