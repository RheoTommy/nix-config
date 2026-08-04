# Step 1 validation

Step 1 is complete only after this checklist passes on the NixOS desktop.
Evaluation on the Ubuntu migration host does not prove runtime behavior.

## 1. Build

```bash
nix flake check --no-build --no-write-lock-file
nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
sudo nixos-rebuild boot --flake .#nixos-desktop
```

Reboot, then select **Niri** in GDM. Keep GNOME available as the recovery
session until this checklist has passed.

## 2. Session

- `niri validate` reports no configuration errors.
- Terminal (`Mod+T`), launcher (`Mod+D`), lock
  (`Super+Alt+L`), Waybar, notifications, and media keys work.
- `systemctl --user --failed` is empty.
- `waybar`, `swayidle`, `niri-background`, `niri-mako`, and
  `niri-polkit-agent` are active under `niri.service`.
- Locking and manual suspend/resume recover correctly. Idle does not suspend
  this desktop; it only locks and powers off the monitors.

## 3. Integration

- File chooser, opening URLs, and screen sharing work through the desktop
  portals.
- A legacy X11 application starts through Xwayland Satellite.
- Network, audio, Bluetooth, and printing work.
- 1Password unlocks, shows polkit prompts, and its CLI integration works.
- NVIDIA output, multiple monitors, logout, GDM login, and the GNOME fallback
  session work.

## 4. Japanese input

Run `fcitx5-diagnose`, then use `Ctrl+Space` to test direct input and Mozc in:

- a native GTK application;
- Google Chrome or another Chromium/Electron application;
- a Qt application such as `fcitx5-configtool`;
- the applications required for daily work, especially 1Password and VS Code.

Prefer native Wayland input protocols. Add `GTK_IM_MODULE` or `QT_IM_MODULE`
only to an application that fails this test; do not set them globally without
a concrete compatibility need.

## 5. Accept or roll back

After the checks pass:

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

If the generation cannot boot, select the previous generation in systemd-boot.
If it boots but the session is broken:

```bash
sudo nixos-rebuild switch --rollback
```

For future unstable updates, run `nix flake update`, repeat the build, and stage
with `boot` before switching.

## References

- [NixOS manual](https://nixos.org/manual/nixos/unstable/)
- [Niri: Important Software](https://niri-wm.github.io/niri/Important-Software.html)
- [Niri: Example systemd Setup](https://niri-wm.github.io/niri/Example-systemd-Setup.html)
- [Niri: Xwayland](https://niri-wm.github.io/niri/Xwayland.html)
- [NixOS Wiki: Fcitx5](https://wiki.nixos.org/wiki/Fcitx5)
- [Fcitx: Using Fcitx 5 on Wayland](https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland/en)
