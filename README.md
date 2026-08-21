# NixOS configuration

My NixOS flake.

## Layout

- `flake.nix`: flake inputs and host definitions
- `hosts/<host>/`: host-specific NixOS configuration
- `home/<user>/`: shared Home Manager configuration for each user
- `modules/`: reusable modules, split into `nixos/` and `home-manager/` as needed

Each host imports the modules it needs and attaches the appropriate user
configurations through `home-manager.users.<user>`.

## Validate

```bash
nix flake check
nixos-rebuild build --flake .#nixos-desktop
```

## Apply

Apply immediately:

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

Use `boot` instead of `switch` to activate the configuration on the next boot.
