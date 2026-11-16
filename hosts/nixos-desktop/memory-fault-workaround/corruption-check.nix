# Fails when the kernel has reported corruption, so that a watcher of this
# service can send a notification. Nothing else would tell: the kernel carries
# on after most reports, and after a panic the host reboots by itself.
{ ... }:

{
  systemd.services.kernel-corruption-check = {
    description = "Check for kernel reports of corruption";
    startAt = "hourly";
    serviceConfig.Type = "oneshot";
    script = ''
      status=0

      # journalctl prints what it finds, which puts it in this unit's log.
      if journalctl -k -q --no-pager \
        -g 'Bad page state|list_(add|del) corruption|\[Hardware Error\]|BTRFS.*(csum failed|checksum error|corrupt)'
      then
        status=1
      fi

      # A panic cannot reach the journal. Its log goes to pstore, and
      # systemd-pstore archives it here on the next boot. Two days keep the
      # alert up long enough to be seen, then let it resolve by itself.
      dumps=$(find /var/lib/systemd/pstore -mindepth 1 -maxdepth 1 -mtime -2 2>/dev/null || true)
      if [ -n "$dumps" ]; then
        echo "The kernel panicked or hit an oops. Its log is in:"
        echo "$dumps"
        status=1
      fi

      exit $status
    '';
  };
}
