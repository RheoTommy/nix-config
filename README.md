# NixOS configuration

Desktop rebuild from GitHub:

```bash
sudo nixos-rebuild switch --flake github:RheoTommy/nix-config#nixos-desktop
```

Local rebuild:

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```
