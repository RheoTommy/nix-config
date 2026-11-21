# Checks which images and leftover build containers the daily prune removes,
# and that the system unit which starts it ends with its result.
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
    podmanPrune.users = [
      "alice"
      "bob"
    ];
    users.users.alice = {
      isNormalUser = true;
      linger = true;
      packages = [ pkgs.buildah ];
    };
    # Never logged in, and no lingering manager.
    users.users.bob.isNormalUser = true;
  };

  testScript = ''
    import shlex

    # The same runtime directory as the user's systemd, so that the test and
    # the service share Podman's runtime state.
    def as_user(user, command):
        return f"su - {user} -c {shlex.quote('export XDG_RUNTIME_DIR=/run/user/$(id -u); ' + command)}"

    def as_alice(command):
        return as_user("alice", command)

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
    # The jump of the clock below would otherwise fire the timers early.
    machine.succeed("systemctl stop podman-prune-alice.timer podman-prune-bob.timer")

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
    machine.succeed("systemctl start podman-prune-alice")

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

    with subtest("a prune that fails makes the system unit fail"):
        override = "~/.config/systemd/user/podman-prune.service.d"
        alice(f"mkdir -p {override} && printf '[Service]\\nExecStart=\\nExecStart=false\\n' > {override}/fail.conf")
        alice("systemctl --user daemon-reload")
        machine.fail("systemctl start podman-prune-alice")
        alice(f"rm -r {override} && systemctl --user daemon-reload")
        machine.succeed("systemctl start podman-prune-alice")

    with subtest("a user who is not logged in is pruned in a session of their own"):
        machine.fail("test -e /run/user/$(id -u bob)")
        machine.succeed("systemctl start podman-prune-bob")
        machine.succeed("loginctl enable-linger bob")
        machine.wait_until_succeeds("test -e /run/user/$(id -u bob)/bus")
        run_root = machine.succeed(as_user("bob", "podman info --format '{{.Store.RunRoot}}'")).strip()
        assert run_root.startswith("/run/user/"), run_root

    with subtest("a prune missed while the machine was off runs at boot"):
        machine.succeed("touch -d 2020-01-01 /var/lib/systemd/timers/stamp-podman-prune-alice.timer")
        machine.shutdown()
        machine.start()
        machine.wait_until_succeeds(
            "journalctl --boot --unit podman-prune-alice --grep 'Finished Prune'", timeout=120
        )
  '';
}
