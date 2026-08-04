# NixOS configuration

## Validate

```bash
nix flake check --no-build --no-write-lock-file
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
```

## Apply

Stage the new generation for the next boot first:

```bash
sudo nixos-rebuild boot --flake .#nixos-desktop
```

After rebooting and completing the runtime checklist, make it the current
generation with `sudo nixos-rebuild switch --flake .#nixos-desktop`.

See [docs/step1-validation.md](docs/step1-validation.md) for the Niri, IME,
portal, 1Password, NVIDIA, and rollback checks.
