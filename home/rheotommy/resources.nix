# Keeps the machine responsive while heavy development work runs, such as test
# suites, builds and deploys started by coding agents.
{ pkgs, ... }:

{
  # Limits are shares of physical memory so the same slice fits any machine.
  # Past MemoryHigh the kernel reclaims harder and slows the work down; past
  # MemoryMax it kills processes inside this slice only, leaving long-running
  # sessions outside it alone.
  systemd.user.slices.heavy.Slice = {
    MemoryHigh = "70%";
    MemoryMax = "80%";
    # zram swap is memory too, and pages swapped out no longer count toward
    # MemoryMax. Bound it so the slice cannot take more memory through swap.
    MemorySwapMax = "4G";
    # Lower priority instead of fewer cores: idle cores stay usable, while
    # interactive work wins under contention.
    CPUWeight = 20;
    IOWeight = 20;
  };

  # `heavy <command> [args...]` runs the command inside that slice, keeping the
  # working directory, arguments and exit status.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "heavy";
      text = ''
        if [ "$#" -eq 0 ]; then
          echo "Usage: heavy <command> [args...]" >&2
          exit 2
        fi
        # Podman normally asks systemd to place each container and build step
        # in a scope of its own, outside this slice. With the cgroupfs manager
        # they stay in the caller's cgroup, so the limits cover them too.
        export CONTAINERS_CONF_OVERRIDE=${pkgs.writeText "heavy-containers.conf" ''
          [engine]
          cgroup_manager = "cgroupfs"
        ''}
        exec systemd-run --user --scope --quiet --slice=heavy.slice -- "$@"
      '';
    })
  ];
}
