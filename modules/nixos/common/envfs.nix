# Serves /bin and /usr/bin for programs that expect a conventional layout.
{ ... }:

{
  # Scripts and tools written for other distributions call programs by fixed
  # paths such as /bin/bash or /usr/bin/bwrap. envfs serves /bin and /usr/bin
  # by looking each name up in the calling process's PATH.
  services.envfs.enable = true;
  # envfs serves only symlinks, so suid and dev give nothing away. Without them,
  # Antigravity's terminal sandbox cannot remount /bin read-only and won't start.
  # TODO: Drop them once agy keeps nosuid and nodev when it remounts.
  fileSystems."/usr/bin".options = [
    "suid"
    "dev"
  ];
  fileSystems."/bin".options = [
    "suid"
    "dev"
  ];
}
