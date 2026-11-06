# Checks that Podman can load the registries config that the module generates.
# Evaluating the system cannot catch a format that Podman rejects, because the
# settings are free-form TOML. Not a plain build: Podman needs /sys/fs/cgroup,
# which the build sandbox lacks.
{ pkgs }:

pkgs.testers.runNixOSTest {
  name = "podman-registries";

  nodes.machine.imports = [ ../modules/nixos/common/podman.nix ];

  testScript = ''
    registries = machine.succeed("podman info --format '{{json .Registries}}'").strip()
    assert registries == '{"search":["docker.io"]}', registries
  '';
}
