# Places the shared disk layout on the KIOXIA drive, the laptop's only drive.
{ ... }:

{
  imports = [ ../../modules/nixos/disk-layout ];

  # By serial, like the desktop, so that a USB drive attached during the install
  # cannot take the name of the drive to erase.
  diskLayout.device = "/dev/disk/by-id/nvme-KIOXIA-EXCERIA_PRO_SSD_Y22A407FKN16";
}
