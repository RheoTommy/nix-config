# Leaves each kind of trace the corruption check looks for, then checks that
# the check fails on it, and that it passes on what only resembles one.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "memory-fault-workaround";

  nodes.machine = {
    imports = [ ../hosts/nixos-desktop/memory-fault-workaround/corruption-check.nix ];

    # The test starts the check more often than systemd allows by default.
    systemd.services.kernel-corruption-check.startLimitIntervalSec = 0;
  };

  testScript = ''
    check = "systemctl start kernel-corruption-check.service"

    def log_to_kernel(line):
        machine.succeed(f"echo '{line}' > /dev/kmsg")
        machine.wait_until_succeeds(f"journalctl -k -q -o cat | grep -F '{line}'", timeout=30)

    machine.wait_for_unit("multi-user.target")

    with subtest("a clean host passes"):
        machine.succeed(check)

    with subtest("a recent panic fails, and an old one passes"):
        machine.succeed("mkdir -p /var/lib/systemd/pstore/1794660095")
        machine.fail(check)
        machine.succeed("touch -d '3 days ago' /var/lib/systemd/pstore/1794660095")
        machine.succeed(check)

    with subtest("a report about another kind of corruption passes"):
        log_to_kernel("exFAT-fs (sda1): Volume was not properly unmounted. Some data may be corrupt.")
        machine.succeed(check)

    # Once one report is in the log every later run fails, so what tells the
    # reports apart is that the check prints the one it found. The kernel's
    # own lines begin "BUG: Bad page state" and "mce: [Hardware Error]", but
    # journald takes such a first word as the sender of a line written from
    # user space, and drops it from the message.
    for report in [
        "Bad page state in process probe  pfn:206b9d",
        "list_del corruption. prev->next should be a, but was b",
        "[Hardware Error]: Machine check events logged",
        "BTRFS warning (device vda): csum failed root 5 ino 257 off 0 csum 0x1 expected csum 0x2 mirror 1",
        "BTRFS critical (device vda): corrupt leaf: root=5 block=1 slot=0",
    ]:
        with subtest(f"fails on: {report}"):
            log_to_kernel(report)
            machine.fail(check)
            machine.wait_until_succeeds(
                f"journalctl -u kernel-corruption-check -o cat | grep -F '{report}'", timeout=30
            )
  '';
}
