# Checks which images and leftover build containers the daily prune removes.
{ pkgs }:

let
  base = pkgs.dockerTools.buildImage {
    name = "base";
    tag = "1";
    copyToRoot = [ pkgs.busybox ];
  };
in
pkgs.testers.runNixOSTest {
  name = "podman-prune";

  nodes.machine = {
    imports = [
      ../modules/nixos/common/podman.nix
      ../modules/nixos/common/podman-prune.nix
    ];
    users.users.alice = {
      isNormalUser = true;
      linger = true;
      packages = [ pkgs.buildah ];
    };
  };

  testScript = ''
    import shlex

    # The same runtime directory as alice's systemd, so that the test and the
    # service share Podman's runtime state.
    def as_alice(command):
        return f"su - alice -c {shlex.quote('export XDG_RUNTIME_DIR=/run/user/$(id -u); ' + command)}"

    def alice(command):
        return machine.succeed(as_alice(command))

    # Two steps, so that the image has an intermediate image as its parent.
    def build(name, parent):
        alice(
            f"mkdir -p {name} && echo {name} > {name}/file"
            f" && printf 'FROM {parent}\\nCOPY file /{name}\\nCOPY file /{name}.2\\n' > {name}/Containerfile"
            f" && podman build -t {name} {name}"
        )

    def exists(kind, name):
        return machine.execute(as_alice(f"podman {kind} exists {name}"))[0] == 0

    def image_count():
        return int(alice("podman images --all --quiet | wc -l"))

    machine.wait_for_unit("user@1000.service")
    machine.wait_for_unit("default.target", user="alice")
    # The jump of the clock below would otherwise fire the timer early.
    machine.succeed("systemctl --user --machine=alice@ stop podman-prune.timer")

    # Built before the clock moves on, so all of these are four days old. The
    # base image is older still: dockerTools dates it at the epoch.
    alice("podman load -i ${base}")
    build("unused", "localhost/base:1")
    build("cache", "localhost/base:1")
    build("held", "localhost/base:1")
    alice("podman create --name holder localhost/held")
    # Two names, as on an image that is also tagged for a registry.
    build("pushed", "localhost/base:1")
    alice("podman tag localhost/pushed registry.example/pushed:1")
    alice("buildah from --name abandoned scratch")
    # What an interrupted build leaves: the mount is gone with the build's
    # namespace, but the container stays marked as mounted.
    alice("buildah from --name mounted scratch")
    alice("buildah unshare buildah mount mounted")

    machine.succeed("date -s '+4 days'")
    build("recent", "localhost/cache")
    alice("buildah from --name running scratch")

    before = image_count()
    machine.succeed("systemctl --user --machine=alice@ start podman-prune")

    with subtest("an old image that nothing builds on is removed"):
        assert not exists("image", "localhost/unused")

    with subtest("an old image with two names is removed"):
        assert not exists("image", "localhost/pushed")
        assert not exists("image", "registry.example/pushed:1")

    with subtest("the removed images' parents are removed with them"):
        assert image_count() == before - 4, (before, image_count())

    with subtest("the ancestors of a recent image are kept, however old"):
        assert exists("image", "localhost/recent")
        assert exists("image", "localhost/cache")
        assert exists("image", "localhost/base:1")

    with subtest("an old image that a container uses is kept"):
        assert exists("image", "localhost/held")

    with subtest("only the build containers older than a day are removed"):
        assert not exists("container", "--external abandoned")
        assert not exists("container", "--external mounted")
        assert exists("container", "--external running")
  '';
}
