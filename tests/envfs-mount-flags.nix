# Checks that the envfs package from the module mounts /bin and /usr/bin
# without nosuid and nodev when the mount options say so. Evaluating the system
# cannot catch this: the options reach /etc/fstab either way, and it is the
# envfs mount helper that decides whether to honour them.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "envfs-mount-flags";

  nodes.machine =
    { lib, ... }:
    {
      imports = [ ../modules/nixos/common/envfs.nix ];

      # Repeats the module's options. In a VM, the NixOS envfs module defines
      # its mounts with mkVMOverride, which discards the module's own
      # definitions at the default priority.
      fileSystems = lib.mkVMOverride {
        "/usr/bin".options = [
          "suid"
          "dev"
        ];
        "/bin".options = [
          "suid"
          "dev"
        ];
      };
    };

  testScript = ''
    for path in ["/bin", "/usr/bin"]:
        options = machine.succeed(f"findmnt --noheadings --output OPTIONS {path}").strip().split(",")
        assert "nosuid" not in options and "nodev" not in options, f"{path}: {options}"
    # The flags must not cost envfs its purpose.
    machine.succeed("/usr/bin/env true")
  '';
}
