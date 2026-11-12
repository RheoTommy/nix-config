# Checks that statfs works on /bin and /usr/bin. Evaluating the system cannot
# catch this: it is the envfs daemon that answers the call.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "envfs-statfs";

  nodes.machine.imports = [ ../modules/nixos/common/envfs.nix ];

  testScript = ''
    for path in ["/bin", "/usr/bin"]:
        machine.succeed(f"stat --file-system {path}")
    # The patch must not cost envfs its purpose.
    machine.succeed("/usr/bin/env true")
  '';
}
