# Serves /bin and /usr/bin for programs that expect a conventional layout.
{ pkgs, ... }:

{
  # Scripts and tools written for other distributions call programs by fixed
  # paths such as /bin/bash or /usr/bin/bwrap. envfs serves /bin and /usr/bin
  # by looking each name up in the calling process's PATH.
  services.envfs.enable = true;
  # envfs 1.3.0 answers every statfs with ENOENT. Antigravity's terminal
  # sandbox reads each mount's flags with statfs before it remounts the mount
  # read-only. When that fails for /bin, it remounts without nosuid and nodev,
  # which the kernel refuses in a user namespace, and the sandbox won't start.
  # Not an overlay: only this service uses the package.
  # TODO: Drop the patch once envfs answers statfs.
  services.envfs.package = pkgs.envfs.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./envfs-statfs.patch ];
  });
}
