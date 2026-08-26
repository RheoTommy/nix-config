# TEMPORARY: diagnostics for the intermittent NVMe/PCIe failures tracked in
# inbox#59. Remove this module and its import once the faulty part is found.
#
# Records storage and PCIe evidence on both SSDs during intermittent failures.
{ pkgs, ... }:

let
  # /home is the WDC filesystem. The normal persistent journal under /var/log
  # remains on the Samsung root filesystem, so each SSD retains evidence about
  # failures affecting the other one.
  monitorDir = "/home/.nvme-monitor";

  kernelMonitor = pkgs.writeShellApplication {
    name = "storage-kernel-monitor";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.systemd
    ];
    text = ''
      monitor_dir=${monitorDir}
      install -d -m 0700 "$monitor_dir"

      boot_id=$(< /proc/sys/kernel/random/boot_id)
      log_file="$monitor_dir/kernel-$boot_id.log"
      filter='nvme|PCIe Bus Error|AER:|RxErr|BadDLLP|Rollover|I/O error|EXT4-fs|blk_update_request|Buffer I/O|NVRM|Xid|watchdog|hung task|soft lockup|hard LOCKUP'

      printf '\n=== monitor started %s ===\n' "$(date --iso-8601=seconds)" >> "$log_file"
      journalctl --boot --dmesg --no-pager -o short-iso-precise \
        | grep -Eai "$filter" >> "$log_file" || true
      sync -f "$monitor_dir"

      journalctl --boot --dmesg --follow --no-pager --lines=0 -o short-iso-precise \
        | grep --line-buffered -Eai "$filter" >> "$log_file"
    '';
  };

  storageSnapshot = pkgs.writeShellApplication {
    name = "storage-snapshot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nvme-cli
      pkgs.pciutils
      pkgs.util-linux
    ];
    text = ''
      shopt -s nullglob

      monitor_dir=${monitorDir}
      install -d -m 0700 "$monitor_dir"

      boot_id=$(< /proc/sys/kernel/random/boot_id)
      snapshot=$(mktemp)
      trap 'rm -f "$snapshot"' EXIT

      {
        printf '\n=== snapshot %s ===\n' "$(date --iso-8601=seconds)"
        uptime
        cat /proc/pressure/io
        findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS /
        findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS /home

        for controller in /dev/nvme[0-9]; do
          [[ -c "$controller" ]] || continue

          name=''${controller##*/}
          printf '\n--- %s ---\n' "$controller"
          printf 'state='; cat "/sys/class/nvme/$name/state"
          printf 'serial='; cat "/sys/class/nvme/$name/serial"
          printf 'model='; cat "/sys/class/nvme/$name/model"

          pci=$(cat "/sys/class/nvme/$name/address")
          device_path=$(readlink -f "/sys/bus/pci/devices/$pci")
          upstream=$(basename "$(dirname "$device_path")")
          printf 'pci=%s upstream=%s\n' "$pci" "$upstream"
          printf 'link_speed='; cat "/sys/bus/pci/devices/$pci/current_link_speed"
          printf 'link_width='; cat "/sys/bus/pci/devices/$pci/current_link_width"

          timeout --kill-after=2s 8s nvme smart-log "$controller" || true
          timeout --kill-after=2s 8s nvme error-log "$controller" --log-entries=8 || true
          lspci -D -s "$pci" -nnvv || true
          if [[ "$upstream" =~ ^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-7]$ ]]; then
            lspci -D -s "$upstream" -nnvv || true
          fi
        done
      } > "$snapshot" 2>&1

      # stdout is stored by journald on Samsung. The appended copy is stored on WDC.
      cat "$snapshot"
      cat "$snapshot" >> "$monitor_dir/snapshots-$boot_id.log"
      sync -f "$monitor_dir"
    '';
  };
in
{
  systemd.services.storage-kernel-monitor = {
    description = "Mirror storage-related kernel events to the WDC filesystem";
    after = [
      "home.mount"
      "systemd-journald.service"
    ];
    requires = [ "home.mount" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathIsMountPoint = "/home";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${kernelMonitor}/bin/storage-kernel-monitor";
      Restart = "always";
      RestartSec = "5s";
      UMask = "0077";
    };
  };

  systemd.services.storage-snapshot = {
    description = "Record NVMe, PCIe, mount, and I/O-pressure state";
    after = [ "home.mount" ];
    requires = [ "home.mount" ];
    unitConfig.ConditionPathIsMountPoint = "/home";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${storageSnapshot}/bin/storage-snapshot";
      IOSchedulingClass = "idle";
      Nice = 10;
      UMask = "0077";
    };
  };

  systemd.timers.storage-snapshot = {
    description = "Record storage state every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Persistent = true;
      Unit = "storage-snapshot.service";
    };
  };
}
