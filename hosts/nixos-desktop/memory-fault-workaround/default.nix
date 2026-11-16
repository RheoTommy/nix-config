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
}
