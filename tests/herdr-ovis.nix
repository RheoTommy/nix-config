# Boots the herdr and Ovis user services from the Home Manager config and
# checks that Ovis can reach herdr and attach to one of its panes.
{ inputs, pkgs }:

pkgs.testers.runNixOSTest {
  name = "herdr-ovis";

  node.specialArgs = { inherit inputs; };

  nodes.machine = {
    imports = [ ../modules/nixos/home-manager-integration ];

    users.users.alice = {
      isNormalUser = true;
      linger = true;
    };
    home-manager.users.alice = {
      imports = [ ../home/rheotommy/terminal.nix ];
      home.stateVersion = "26.05";
    };

    environment.systemPackages = [
      pkgs.curl
      (pkgs.python3.withPackages (ps: [ ps.websockets ]))
    ];
  };

  testScript = ''
    import json

    # The user units exist only once activation has linked them; waiting on
    # them earlier sees an inactive unit with no job and fails at once.
    machine.wait_for_unit("home-manager-alice.service")
    machine.wait_for_unit("herdr.service", "alice")
    machine.wait_for_unit("ovis.service", "alice")
    machine.wait_for_open_port(7317)

    # Ovis answers 200 only after a ping to herdr succeeds.
    health = json.loads(machine.succeed("curl -sSf http://127.0.0.1:7317/api/health"))
    print(health)
    assert health["ok"] is True, health
    assert isinstance(health["herdr"]["protocol"], int), health
    assert health["herdr"]["terminal_attach"] is True, health

    machine.succeed("curl -sSf http://127.0.0.1:7317/ | grep -q '<div id=\"root\"'")

    created = json.loads(machine.succeed("su - alice -c 'herdr workspace create'"))
    pane = created["result"]["root_pane"]["pane_id"]
    machine.succeed(f"python3 ${./ovis-attach.py} ws://127.0.0.1:7317/ws {pane}")
  '';
}
