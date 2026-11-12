# Serves /bin and /usr/bin for programs that expect a conventional layout.
{ pkgs, ... }:

{
  # Scripts and tools written for other distributions call programs by fixed
  # paths such as /bin/bash or /usr/bin/bwrap. envfs serves /bin and /usr/bin
  # by looking each name up in the calling process's PATH.
  services.envfs.enable = true;
  # envfs serves only symlinks, so suid and dev give nothing away. Without them,
  # Antigravity's terminal sandbox cannot remount /bin read-only and won't start:
  # it drops nosuid and nodev in the remount, and the kernel refuses to clear
  # flags that a user namespace inherited.
  # TODO: Drop them, and the patch, once agy keeps nosuid and nodev when it
  # remounts.
  fileSystems."/usr/bin".options = [
    "suid"
    "dev"
  ];
  fileSystems."/bin".options = [
    "suid"
    "dev"
  ];
  # envfs 1.3.0 ignores suid and dev, and its FUSE library then mounts with
  # nosuid and nodev. Not an overlay: only this service uses the package.
  services.envfs.package = pkgs.envfs.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./envfs-suid-dev.patch ];
  });
}
