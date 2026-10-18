# Declares the partition layout of the WDC drive that holds the whole system.
{ inputs, ... }:

{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices.disk.main = {
    type = "disk";
    # Address the drive by serial: nvme0/nvme1 numbering swaps between boots on
    # this machine, and the wrong guess would wipe the other drive.
    device = "/dev/disk/by-id/nvme-WDC_WDS100T2B0C-00PXH0_21155T484612";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          # Room for many generations, each with its own kernel and an
          # NVIDIA-sized initrd.
          size = "2G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            # Separate subvolumes let /home be snapshotted without pulling in
            # the Nix store, which is rebuildable and not worth keeping.
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };

  # Keep early-boot messages in the persistent journal.
  fileSystems."/var/log".neededForBoot = true;

  # Re-read every block monthly so silent corruption shows up in the journal.
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };
}
