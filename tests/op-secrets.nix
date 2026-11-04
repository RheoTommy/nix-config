# Fetches secrets through a stand-in for the 1Password CLI, then checks the
# files, when the services that read them start and restart, and what happens
# when a fetch fails.
{ pkgs }:

let
  # Replaces each reference with its path and the version in
  # /run/fake-op/version. While /run/fake-op/down exists, it fails partway
  # through writing.
  fakeOp = pkgs.writeShellScriptBin "op" ''
    set -eu
    [ "$1" = inject ]
    [ "$OP_SERVICE_ACCOUNT_TOKEN" = test-token ]
    shift
    while (( $# > 0 )); do
      case $1 in
        -i) input=$2; shift ;;
        -o) output=$2; shift ;;
      esac
      shift
    done
    if [ -e /run/fake-op/down ]; then
      echo partial > "$output"
      exit 1
    fi
    version=$(cat /run/fake-op/version 2>/dev/null || echo 1)
    sed -E "s|\{\{ op://([^ ]+) \}\}|\1@$version|g" "$input" > "$output"
  '';
  path = "/var/lib/op-secrets";
in
pkgs.testers.runNixOSTest {
  name = "op-secrets";

  nodes.machine = {
    imports = [ ../modules/nixos/op-secrets ];

    opSecrets = {
      package = fakeOp;
      files = {
        app-env = {
          template = "SECRET={{ op://vault/app/password }}\n";
          services = [ "app" ];
        };
        other.template = "{{ op://vault/other/password }}";
      };
    };
    environment.etc."op-secrets/token" = {
      text = "test-token";
      mode = "0600";
    };

    systemd.services.app = {
      wantedBy = [ "multi-user.target" ];
      script = ''
        echo attempt
        value=$(< ${path}/app-env)
        echo "started with $value"
        exec sleep infinity
      '';
    };
  };

  testScript = ''
    def show(prop, unit):
        return machine.succeed(f"systemctl show -P {prop} {unit}").strip()

    def invocation():
        return show("InvocationID", "app.service")

    def fetch(command="succeed"):
        # This test starts the unit faster than systemd's start limit allows.
        machine.succeed("systemctl reset-failed op-secrets.service")
        getattr(machine, command)("systemctl start op-secrets.service")

    machine.wait_for_unit("app.service")
    machine.wait_for_unit("op-secrets.timer")

    with subtest("the files are written before the services that read them start"):
        machine.succeed("grep -qx 'SECRET=vault/app/password@1' ${path}/app-env")
        machine.succeed("grep -qx 'vault/other/password@1' ${path}/other")
        assert machine.succeed("journalctl -u app.service | grep -c attempt").strip() == "1"
        machine.succeed("journalctl -u app.service | grep -q 'started with SECRET=vault/app/password@1'")
        fetched = int(show("ExecMainExitTimestampMonotonic", "op-secrets.service"))
        started = int(show("ExecMainStartTimestampMonotonic", "app.service"))
        assert 0 < fetched < started
        machine.succeed('test "$(stat -c %a:%U ${path})" = 700:root')
        machine.succeed('test "$(stat -c %a:%U ${path}/app-env)" = 600:root')

    with subtest("an unchanged value leaves the services running"):
        before = invocation()
        fetch()
        machine.sleep(2)
        assert invocation() == before
        machine.succeed("test ! -e ${path}/app-env.new")

    with subtest("a changed value is written and restarts its services"):
        before = invocation()
        machine.succeed("mkdir -p /run/fake-op && echo 2 > /run/fake-op/version")
        fetch()
        machine.succeed("grep -qx 'SECRET=vault/app/password@2' ${path}/app-env")
        machine.wait_until_succeeds(f'test "$(systemctl show -P InvocationID app.service)" != {before}')
        machine.wait_for_unit("app.service")
        machine.succeed("journalctl -u app.service | grep -q 'started with SECRET=vault/app/password@2'")

    with subtest("a failed fetch keeps the previous value and fails the unit"):
        before = invocation()
        machine.succeed("touch /run/fake-op/down && echo 3 > /run/fake-op/version")
        fetch("fail")
        machine.succeed("systemctl is-failed op-secrets.service")
        machine.succeed("grep -qx 'SECRET=vault/app/password@2' ${path}/app-env")
        machine.succeed("test ! -e ${path}/app-env.new")
        assert invocation() == before
        machine.succeed("journalctl -u op-secrets.service | grep -q 'app-env: could not fetch; keeping the previous value'")

    with subtest("a failed fetch with no previous value fails"):
        machine.succeed("rm ${path}/other")
        fetch("fail")
        machine.succeed("journalctl -u op-secrets.service | grep -q 'other: could not fetch, and there is no previous value'")
        machine.succeed("grep -qx 'SECRET=vault/app/password@2' ${path}/app-env")

    with subtest("restarting a service does not wait for a fetch"):
        before = show("InvocationID", "op-secrets.service")
        machine.succeed("systemctl restart app.service")
        machine.wait_for_unit("app.service")
        assert show("InvocationID", "op-secrets.service") == before

    with subtest("a service that failed for lack of its file starts once the file exists"):
        machine.succeed("systemctl stop app.service")
        machine.succeed("rm ${path}/app-env")
        machine.execute("systemctl start app.service")
        machine.wait_until_succeeds("systemctl is-failed app.service")
        machine.succeed("rm /run/fake-op/down")
        fetch()
        machine.wait_for_unit("app.service")
        machine.succeed("journalctl -u app.service | grep -q 'started with SECRET=vault/app/password@3'")
  '';
}
