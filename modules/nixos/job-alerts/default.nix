# Sends a phone notification through ntfy when a watched job stops succeeding.
# Each job records its result when it ends, and an hourly check reports every
# job to Gatus: a failure if its last run failed or if it has not succeeded for
# too long. The latter also catches a job that never ran, such as one skipped
# by a condition. Gatus shows the reports and turns failures into
# notifications. Gatus cannot report its own failure, so that goes to ntfy
# directly.
#
# The secrets stay outside the store and are created by hand once, before the
# first switch, since Gatus does not start without them:
#   /etc/gatus/env  NTFY_TOPIC=<topic>   the ntfy topic, also kept in 1Password
#                   GATUS_TOKEN=<random> lets the reports reach Gatus
# Restart Gatus after changing it.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.jobAlerts;
  curl = lib.getExe pkgs.curl;
  secrets = "/etc/gatus/env";
  state = "/var/lib/job-alerts";
  gatus = "http://127.0.0.1:${toString config.services.gatus.settings.web.port}";

  # Reports job $1 to Gatus as succeeded ($2 = true) or failed with reason $3.
  # The retries cover a report sent while Gatus restarts, as on a switch.
  push = pkgs.writeShellScript "job-alerts-push" ''
    ${curl} -fsS --retry 5 --retry-connrefused --retry-delay 5 -X POST \
      -H "Authorization: Bearer $GATUS_TOKEN" \
      --url-query "success=$2" --url-query "error=''${3:-}" \
      "${gatus}/api/v1/endpoints/jobs_$1/external"
  '';

  unit = description: script: {
    inherit description script;
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = secrets;
      StateDirectory = "job-alerts";
    };
  };
  # A template whose instance is the job's name.
  record =
    description: script:
    unit description script
    // {
      scriptArgs = "%i";
    };
in
{
  options.jobAlerts = {
    jobs = lib.mkOption {
      type = lib.types.attrsOf lib.types.ints.positive;
      default = { };
      example = {
        btrbk-home = 2;
      };
      description = "The systemd services to watch, each with the hours it may go without succeeding.";
    };
    ntfyUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.sh";
      description = "The ntfy server. Tests point it at a local one.";
    };
  };

  config = lib.mkIf (cfg.jobs != { }) {
    assertions = [
      {
        assertion = lib.all (name: builtins.match "[a-z0-9-]+" name != null) (builtins.attrNames cfg.jobs);
        message = "jobAlerts.jobs: use only lowercase letters, digits and hyphens, which Gatus keeps in endpoint keys.";
      }
    ];

    services.gatus = {
      environmentFile = secrets;
      settings = {
        alerting.ntfy = {
          url = cfg.ntfyUrl;
          topic = "\${NTFY_TOPIC}";
          default-alert = {
            # The default of three would wait three hours, or three runs.
            failure-threshold = 1;
            success-threshold = 1;
            send-on-resolved = true;
          };
        };
        external-endpoints = lib.mapAttrsToList (name: _: {
          inherit name;
          group = "jobs";
          token = "\${GATUS_TOKEN}";
          # Catches the hourly check itself stopping. Gatus's heartbeat cannot
          # watch the jobs directly: it counts from when Gatus started, so for
          # a weekly job, restarting Gatus more often than weekly would keep it
          # from ever running out.
          heartbeat.interval = "2h";
          alerts = [ { type = "ntfy"; } ];
        }) cfg.jobs;
      };
    };

    systemd.services = lib.mkMerge [
      (lib.mapAttrs (name: _: {
        onSuccess = [ "job-alerts-succeeded@${name}.service" ];
        onFailure = [ "job-alerts-failed@${name}.service" ];
      }) cfg.jobs)
      {
        "job-alerts-succeeded@" = record "Record that %i succeeded" ''
          date +%s > ${state}/$1
          rm -f ${state}/$1.failed
          ${push} "$1" true
        '';
        "job-alerts-failed@" = record "Record that %i failed" ''
          touch ${state}/$1.failed
          ${push} "$1" false "the last run failed; see journalctl -u $1"
        '';

        job-alerts-check =
          unit "Report the watched jobs to Gatus" ''
            check() {
              local name=$1 hours=$2
              # A job added since the last check gets its full time from now.
              [ -e ${state}/$name ] || date +%s > ${state}/$name
              if [ -e ${state}/$name.failed ]; then
                ${push} "$name" false "the last run failed; see journalctl -u $name"
              elif (( $(date +%s) - $(< ${state}/$name) > hours * 3600 )); then
                ${push} "$name" false "no success for over $hours hours"
              else
                ${push} "$name" true
              fi
            }
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: hours: "check ${name} ${toString hours}") cfg.jobs
            )}
          ''
          // {
            startAt = "hourly";
          };

        gatus = {
          onFailure = [ "gatus-failure-alert.service" ];
          # Restart without passing through the failed state, so that a crash
          # a restart fixes stays quiet and only giving up sends a notification.
          serviceConfig.RestartMode = "direct";
        };
        gatus-failure-alert = {
          description = "Send a notification that Gatus failed";
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = secrets;
          };
          # The network may be down too, so keep trying for a while.
          script = ''
            ${curl} -fsS --retry 10 --retry-delay 30 --retry-all-errors \
              -H "Title: Gatus failed on ${config.networking.hostName}" \
              -d "Job alerts are off until it runs again. See journalctl -u gatus." \
              "${cfg.ntfyUrl}/$NTFY_TOPIC"
          '';
        };
      }
    ];
  };
}
