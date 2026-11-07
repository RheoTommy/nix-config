# Runs commands on a schedule, each as a given user, and alerts when one stops
# succeeding. This holds only when a command runs and what it may read: what the
# command does, and how it stays up to date, are its own business.
#
# These are system services running as the user, not user services: only a
# system service can read the root-owned credentials and report to jobAlerts.
# A job that reads the user's keyring, as gh does, fails after a reboot until
# someone logs in, since the login unlocks it.
{ config, lib, ... }:

let
  cfg = config.scheduledJobs;
in
{
  options.scheduledJobs = lib.mkOption {
    default = { };
    description = "The jobs to run. This configuration is public, so keep their names and commands neutral.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          user = lib.mkOption {
            type = lib.types.str;
            description = "The user that runs the command.";
          };
          command = lib.mkOption {
            type = lib.types.str;
            example = "/home/alice/bin/report --weekly";
            description = "The shell command to run. It finds the user's tools on PATH.";
          };
          onCalendar = lib.mkOption {
            type = lib.types.str;
            example = "hourly";
            description = "When to run, as in systemd.time(7).";
          };
          maxHoursWithoutSuccess = lib.mkOption {
            type = lib.types.ints.positive;
            description = "How long the job may go without succeeding before an alert.";
          };
          credentials = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = {
              token = "/var/lib/op-secrets/token";
            };
            description = "Root-owned files that the job reads from $CREDENTIALS_DIRECTORY/<name>.";
          };
        };
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    jobAlerts.jobs = lib.mapAttrs (_: job: job.maxHoursWithoutSuccess) cfg;

    systemd.services = lib.mapAttrs (name: job: {
      description = "Run the scheduled job ${name}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = [
        "/etc/profiles/per-user/${job.user}"
        "/run/current-system/sw"
      ];
      startAt = job.onCalendar;
      serviceConfig = {
        Type = "oneshot";
        User = job.user;
        # A oneshot has no time limit by default, so a job stuck on a prompt
        # would never fail.
        TimeoutStartSec = "30min";
        LoadCredential = lib.mapAttrsToList (id: path: "${id}:${path}") job.credentials;
      };
      script = job.command;
    }) cfg;

    systemd.timers = lib.mapAttrs (_: _: {
      timerConfig.Persistent = true;
    }) cfg;
  };
}
