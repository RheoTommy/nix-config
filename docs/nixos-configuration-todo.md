# NixOS Configuration Todo

Scope: NixOS configuration only. User-level tools, dotfiles, shell setup, editor
setup, and per-user packages belong under Home Manager unless they need system
services, kernel support, device access, or OS-level permissions.

## Current Baseline

- [x] Flakes enabled for Nix.
- [x] Unfree packages allowed globally.
- [x] Redistributable firmware enabled.
- [x] NetworkManager enabled.
- [x] Tailscale enabled for private tailnet connectivity. Public Tailscale UDP
      firewall opening is left at the NixOS default unless connectivity requires
      it.
- [x] English display locale with Japan-specific locale categories.
- [x] Japanese-capable fonts installed.
- [x] Printing service enabled.
- [x] PipeWire audio enabled.
- [x] `rheotommy` system user created with `wheel` and `networkmanager`.
- [x] Desktop GNOME/GDM enabled.
- [x] Desktop NVIDIA RTX 3070 graphics and suspend support configured.
- [x] Home Manager integrated into NixOS activation.

## Next NixOS Decisions

- [x] SSD/NVMe maintenance: NixOS 25.11 defaults
      `services.fstrim.enable` to `true` with a weekly interval, so no explicit
      setting is needed.

- [x] Firewall policy: keep NixOS defaults implicit. The firewall is enabled by
      default, Avahi opens UDP 5353 for GNOME local discovery, and no public
      SSH/application ports are opened.

- [ ] Nix daemon policy: decide whether to configure `nix.settings.trusted-users`
      for `rheotommy`.

- [ ] Nix store maintenance: decide whether to enable automatic garbage
      collection and `nix.settings.auto-optimise-store`.

- [ ] Binary cache policy: decide whether any extra substituters or trusted
      public keys are needed beyond the default NixOS cache.

- [ ] SSH access: decide between regular OpenSSH over Tailscale and Tailscale
      SSH. If regular OpenSSH is used, require key-only login and allow port 22
      only on the Tailscale interface.

- [ ] Local service discovery: decide whether to enable Avahi/mDNS for printer,
      scanner, SSH, or local hostname discovery.

- [ ] Bluetooth: decide whether Bluetooth should be enabled at the OS level and
      whether to manage it through GNOME only or add extra tooling.

- [ ] Printing and scanning: review printer driver needs, network printer
      discovery, and scanner support.

- [ ] Japanese input method: decide whether to configure fcitx5/Mozc at the
      NixOS layer, then keep user preferences in Home Manager where possible.

- [ ] Desktop power behavior: review GNOME/GDM/systemd power behavior only if
      suspend/resume shows remaining issues.

- [ ] Container runtime: decide whether to enable Docker, Podman, or neither.

- [ ] Virtualization: decide whether to enable libvirt, QEMU/KVM, VirtualBox, or
      none.

- [ ] Secrets management: decide whether to introduce `sops-nix`, `agenix`, or
      leave secrets outside this repository for now.

- [ ] Security baseline: review sudo/wheel policy, polkit expectations, and any
      system-level integration for tools like 1Password.

- [ ] Laptop hardware path: when the laptop host is added, review
      `nixos-hardware`, power management, battery behavior, touchpad, fingerprint,
      Wi-Fi/Bluetooth, and suspend quirks separately from Desktop.

## Module Structure Follow-Ups

- [ ] Split `modules/nixos/common/default.nix` only when it becomes hard to scan.
      Likely future splits: `nix`, `locale`, `networking`, `audio`, `fonts`,
      `users`, and `home-manager-integration`.

- [ ] Keep host-specific hardware and boot settings in `hosts/<host>/`.

- [ ] Keep Home Manager user configuration under `home/<user>/` and reusable
      Home Manager modules under `modules/home-manager/`.
