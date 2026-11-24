# Places the shared disk layout on the WDC drive that holds the whole system.
{ ... }:

{
  imports = [ ../../modules/nixos/disk-layout ];

  # Address the drive by serial: nvme0/nvme1 numbering swaps between boots on
  # this machine, and the wrong guess would wipe the other drive.
  diskLayout.device = "/dev/disk/by-id/nvme-WDC_WDS100T2B0C-00PXH0_21155T484612";
}
