# TEMPORARY. Delete this directory once the fault below is fixed.
#
# The kernel has found corrupted memory twice in four weeks: a free page with
# one stray bit in its metadata, and a futex wait list with one broken pointer,
# which took the host down. Both fit a single flipped bit, so the RAM is the
# main suspect. Confirming that takes an overnight Memtest, and the host cannot
# be offline that long yet. Until then, the settings here keep the host running
# and make every new sign of the fault visible.
#
# To delete it, remove this directory, its import in ../default.nix,
# tests/memory-fault-workaround.nix and that test's line in flake.nix.
{ ... }:

{
  imports = [ ./corruption-check.nix ];

  jobAlerts.jobs.kernel-corruption-check = 3;

  # An oops already ends in a reboot (../default.nix). Corrupted memory can
  # also hang the kernel without one, which would leave this host out of
  # reach until someone resets it by hand, so reboot on a lockup too.
  boot.kernel.sysctl = {
    "kernel.softlockup_panic" = 1;
    "kernel.hardlockup_panic" = 1;
  };
  # For a hang that the kernel cannot notice by itself.
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";
  # systemd takes the first watchdog, which on this board is the one meant for
  # recovering from failed overclocking. Leave it only iTCO_wdt, the
  # general-purpose one.
  boot.blacklistedKernelModules = [ "intel_oc_wdt" ];

  # Tests all memory early in each boot, logs what fails and keeps it out of
  # use. Four passes write every bit as 0 and as 1, each time next to equal and
  # next to opposite bits: all zeros, all ones, 0x55.. and 0xaa...
  boot.kernelParams = [ "memtest=4" ];
}
