# Declares the partition layout of a host whose whole system lives on one
# drive: an EFI system partition, and btrfs subvolumes for the rest.
{
  config,
  inputs,
  lib,
  ...
}:

let
  # zstd saves space and writes on source trees and logs; access times would
  # turn every read into a write.
  mountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  options.diskLayout.device = lib.mkOption {
    type = lib.types.str;
    example = "/dev/disk/by-id/nvme-WDC_WDS100T2B0C-00PXH0_21155T484612";
    description = "The drive to partition. Installing with disko erases all of it.";
  };

  config = {
    disko.devices.disk.main = {
      type = "disk";
      inherit (config.diskLayout) device;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            # Room for many generations, each with its own kernel and initrd,
            # which grows to NVIDIA size on a host with that driver.
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
                  inherit mountOptions;
                };
                "@home" = {
                  mountpoint = "/home";
                  inherit mountOptions;
                };
                "@nix" = {
                  mountpoint = "/nix";
                  inherit mountOptions;
                };
                "@log" = {
                  mountpoint = "/var/log";
                  inherit mountOptions;
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

    # The layout has no swap partition. Compressed in-memory swap gives the
    # kernel room to reclaim idle pages without a disk-backed swap device. The
    # default size (50% of RAM) is enough for now.
    zramSwap.enable = true;
    # The kernel defaults assume swap on a disk. Swapping to zram costs only
    # compression, so prefer it over dropping file cache, and read back one
    # page at a time since readahead saves no seek on memory.
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
    };
  };
}
