# Runs a command kept outside the configuration, then checks what it gets and
# that its failure reaches the alerts.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "scheduled-jobs";

  nodes.machine = {
    imports = [
      ../modules/nixos/job-alerts
      ../modules/nixos/scheduled-jobs
    ];

    users.users.alice = {
      isNormalUser = true;
      packages = [ pkgs.hello ];
    };

    scheduledJobs.probe = {
      user = "alice";
      command = "/home/alice/probe first second";
      onCalendar = "hourly";
      maxHoursWithoutSuccess = 3;
      credentials.token = "/etc/probe-token";
    };

    environment.etc.probe-token = {
      text = "test-token";
      mode = "0600";
    };

    services.gatus = {
      enable = true;
      settings = {
        web.port = 8080;
        # Gatus refuses to start without at least one endpoint of its own.
        endpoints = [
          {
            name = "self";
            url = "tcp://127.0.0.1:8080";
            interval = "1h";
            conditions = [ "[CONNECTED] == true" ];
          }
        ];
      };
    };
    jobAlerts.environmentFile = "/etc/gatus/env";
    environment.etc."gatus/env" = {
      text = ''
        NTFY_TOPIC=test-topic
        GATUS_TOKEN=test-token
      '';
      mode = "0600";
    };
  };

  testScript = ''
    import shlex

    def alice(command):
        return machine.succeed(f"su - alice -c {shlex.quote(command)}")

    def write_probe(script):
        alice(f"printf '#!/bin/sh\\n%s\\n' {shlex.quote(script)} > probe && chmod +x probe")

    machine.wait_for_unit("multi-user.target")

    with subtest("a job has a timer that catches up on missed runs"):
        machine.succeed("systemctl is-active probe.timer")
        assert machine.succeed("systemctl show -P Persistent probe.timer").strip() == "yes"

    with subtest("a command runs as the user, with its arguments and credential"):
        write_probe('id -un > ~/user; echo "$@" > ~/args; cp "$CREDENTIALS_DIRECTORY/token" ~/token')
        machine.succeed("systemctl start probe")
        assert alice("cat ~/user").strip() == "alice"
        assert alice("cat ~/args").strip() == "first second"
        assert alice("cat ~/token").strip() == "test-token"
        machine.fail("su - alice -c 'cat /etc/probe-token'")

    with subtest("a command finds the user's tools"):
        write_probe("hello > ~/greeting")
        machine.succeed("systemctl start probe")
        assert "Hello" in alice("cat ~/greeting")

    with subtest("a failure reaches the alerts"):
        write_probe("exit 1")
        machine.fail("systemctl start probe")
        machine.wait_until_succeeds("test -e /var/lib/job-alerts/probe.failed", timeout=30)
  '';
}
