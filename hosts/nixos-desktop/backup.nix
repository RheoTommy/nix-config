# Keeps hourly snapshots of /home on the system drive, and backs /home up with
# restic to the IODATA USB drive daily and to Google Drive weekly.
#
# Secrets stay outside the store and are created by hand once:
#   /etc/restic/password     the restic repository password (also kept in 1Password)
#   /etc/restic/rclone.conf  the rclone remote "gdrive", from `rclone config`
{ lib, pkgs, ... }:

let
  btrfs = lib.getExe' pkgs.btrfs-progs "btrfs";

  # restic reads a read-only snapshot rather than the live /home, so files that
  # change during the run, such as SQLite databases, are captured consistently.
  backup =
    name:
    let
      snapshot = "/home/.snapshots/restic-${name}";
    in
    {
      paths = [ snapshot ];
      exclude = [
        "rheotommy/.cache"
        "rheotommy/.local/share/containers"
        "node_modules"
        ".venv"
        ".direnv"
      ];
      passwordFile = "/etc/restic/password";
      initialize = true;
      backupPrepareCommand = ''
        if [ -e ${snapshot} ]; then ${btrfs} subvolume delete ${snapshot}; fi
        ${btrfs} subvolume snapshot -r /home ${snapshot}
      '';
      backupCleanupCommand = "${btrfs} subvolume delete ${snapshot}";
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 8"
        "--keep-monthly 12"
      ];
    };
in
{
  services.btrbk.instances.home = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2h";
      snapshot_preserve = "24h 7d 4w";
      subvolume."/home".snapshot_dir = "/home/.snapshots";
    };
  };
  # btrbk does not create its snapshot directory.
  systemd.tmpfiles.rules = [ "d /home/.snapshots 0755 root root -" ];

  # Mounted on first access and skipped when unplugged, since the drive is
  # usually attached but sometimes taken away.
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-label/backup";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
      "nofail"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.device-timeout=5s"
    ];
  };

  services.restic.backups = {
    iodata = backup "iodata" // {
      repository = "/mnt/backup/restic";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
    gdrive = backup "gdrive" // {
      repository = "rclone:gdrive:restic/nixos-desktop";
      rcloneConfigFile = "/etc/restic/rclone.conf";
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
  # Skip rather than fail while the drive is unplugged.
  systemd.services.restic-backups-iodata.unitConfig.ConditionPathExists = "/dev/disk/by-label/backup";
}
