# Runs jobs that succeed, fail and are skipped, then checks what Gatus records
# for each and what reaches a stand-in for ntfy, including when Gatus itself
# fails.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "job-alerts";

  nodes.machine = {
    imports = [ ../modules/nixos/job-alerts ];

    services.gatus = {
      enable = true;
      settings = {
        web.port = 8080;
        # Gatus refuses to start without at least one endpoint of its own.
        endpoints = [
          {
            name = "sink";
            url = "tcp://127.0.0.1:2586";
            interval = "1h";
            conditions = [ "[CONNECTED] == true" ];
          }
        ];
      };
    };
    jobAlerts = {
      ntfyUrl = "http://127.0.0.1:2586";
      jobs = {
        probe-ok = 1;
        probe-fail = 1;
        probe-skip = 2;
      };
    };
    environment.etc."gatus/env" = {
      text = ''
        NTFY_TOPIC=test-topic
        GATUS_TOKEN=test-token
      '';
      mode = "0600";
    };

    systemd.services = {
      probe-ok = {
        serviceConfig.Type = "oneshot";
        script = "true";
      };
      probe-fail = {
        serviceConfig.Type = "oneshot";
        script = "false";
      };
      probe-skip = {
        serviceConfig.Type = "oneshot";
        unitConfig.ConditionPathExists = "/nonexistent";
        script = "true";
      };
      ntfy-sink = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${pkgs.python3.interpreter} ${./ntfy-sink.py} 2586 /tmp/ntfy.log";
      };
    };

    environment.systemPackages = [
      pkgs.curl
      pkgs.jq
    ];
  };

  testScript = ''
    def last_result(job, jq_test):
        machine.wait_until_succeeds(
            f"curl -sSf http://127.0.0.1:8080/api/v1/endpoints/jobs_{job}/statuses"
            f" | jq -e '.results[-1] | {jq_test}'",
            timeout=60,
        )

    def wait_for_notification(title):
        machine.wait_until_succeeds(
            f"jq -e --arg title '{title}'"
            " 'select(.topic == \"test-topic\" and .title == $title)' /tmp/ntfy.log",
            timeout=60,
        )

    def notifications(title):
        return int(machine.succeed(
            f"jq -s --arg title '{title}' 'map(select(.title == $title)) | length' /tmp/ntfy.log"
        ))

    machine.wait_for_unit("ntfy-sink.service")
    machine.wait_for_unit("gatus.service")
    machine.wait_for_open_port(2586)
    machine.wait_for_open_port(8080)

    with subtest("a job that succeeds is reported at once"):
        machine.succeed("systemctl start probe-ok.service")
        last_result("probe-ok", ".success")

    with subtest("a job that fails is reported and alerted at once"):
        machine.fail("systemctl start probe-fail.service")
        last_result("probe-fail", ".success == false")
        wait_for_notification("Gatus: jobs/probe-fail")

    with subtest("the hourly check keeps a failed job failed"):
        machine.succeed("systemctl start job-alerts-check.service")
        last_result("probe-fail", '.success == false and (.errors[0] | startswith("the last run failed"))')
        last_result("probe-ok", ".success")
        assert notifications("Gatus: jobs/probe-fail") == 1

    with subtest("a skipped job records nothing"):
        machine.succeed("systemctl start probe-skip.service")
        machine.succeed('test "$(systemctl show -P ConditionResult probe-skip.service)" = no')
        machine.sleep(2)
        machine.succeed(
            'test "$(systemctl show -P ExecMainStartTimestampMonotonic'
            ' job-alerts-succeeded@probe-skip.service)" = 0'
        )

    with subtest("a job with no success for too long is alerted"):
        # The first check above gave probe-skip its full time from then.
        machine.succeed("echo $(( $(date +%s) - 3 * 3600 )) > /var/lib/job-alerts/probe-skip")
        machine.succeed("systemctl start job-alerts-check.service")
        last_result("probe-skip", '.success == false and .errors[0] == "no success for over 2 hours"')
        wait_for_notification("Gatus: jobs/probe-skip")

    with subtest("a later success resolves the alert"):
        machine.succeed("systemctl start probe-ok.service")
        machine.succeed("rm /var/lib/job-alerts/probe-fail.failed")
        machine.succeed("systemctl start job-alerts-check.service")
        last_result("probe-fail", ".success")
        machine.wait_until_succeeds(
            "jq -e 'select(.title == \"Gatus: jobs/probe-fail\""
            " and (.message | startswith(\"An alert has been resolved\")))' /tmp/ntfy.log",
            timeout=60,
        )

    with subtest("a crash that a restart fixes sends nothing"):
        machine.succeed("systemctl kill --signal=KILL gatus.service")
        machine.wait_until_succeeds('test "$(systemctl show -P NRestarts gatus.service)" = 1')
        machine.wait_for_unit("gatus.service")
        machine.sleep(2)
        assert notifications("Gatus failed on machine") == 0

    with subtest("Gatus giving up is sent to ntfy directly"):
        # A kill that lands mid-restart does nothing, so a fixed number of
        # kills may stop short of the start limit.
        machine.wait_until_succeeds(
            "systemctl kill --signal=KILL gatus.service; systemctl is-failed gatus.service",
            timeout=60,
        )
        wait_for_notification("Gatus failed on machine")
  '';
}
