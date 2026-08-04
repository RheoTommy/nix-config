# NixOS Configuration Todo

Scope: NixOS configuration only. User-level tools, dotfiles, shell setup, editor
setup, and per-user packages belong under Home Manager unless they need system
services, kernel support, device access, or OS-level permissions.

## Current Baseline

- [x] Flakes enabled for Nix.
- [x] Unfree packages allowed globally.
- [x] Redistributable firmware enabled.
- [x] Bluetooth enabled at the OS level. GNOME provides the UI, so no separate
      Blueman service is enabled.
- [x] NetworkManager enabled.
- [x] Tailscale enabled for private tailnet connectivity. Public Tailscale UDP
      firewall opening is left at the NixOS default unless connectivity requires
      it.
- [x] English display locale with Japan-specific locale categories.
- [x] Japanese-capable fonts installed.
- [x] Japanese input method enabled with Fcitx5 and Mozc, with a declarative US
      keyboard/Mozc profile and native Wayland frontend.
- [x] Printing service enabled.
- [x] PipeWire audio enabled.
- [x] `rheotommy` system user created with `wheel` and `networkmanager`.
- [x] Desktop Niri/GDM enabled, with GNOME retained as a temporary recovery
      session.
- [x] Niri session services configured: Waybar, Mako, Fuzzel, swayidle,
      swaylock, background, Xwayland Satellite, and a polkit agent.
- [x] Desktop NVIDIA RTX 3070 graphics and suspend support configured.
- [x] Desktop automatic suspend disabled on AC: both GDM greeter policy and
      GNOME user-session policy are owned by `hosts/nixos-desktop`; the
      user-session value lives in `hosts/nixos-desktop/home.nix` and is applied
      through Home Manager dconf.
- [x] Home Manager integrated into NixOS activation.

## Next NixOS Decisions

- [x] SSD/NVMe maintenance: NixOS 25.11 defaults
      `services.fstrim.enable` to `true` with a weekly interval, so no explicit
      setting is needed.

- [x] Firewall policy: keep NixOS defaults implicit. The firewall is enabled by
      default, Avahi opens UDP 5353 for GNOME local discovery, and no public
      SSH/application ports are opened.

- [x] Nix daemon policy: keep default trusted users. `root` is the only trusted
      user, so privileged rebuilds still go through `sudo`.

- [x] Nix store maintenance: run weekly garbage collection for generations
      older than 30 days and weekly scheduled store optimisation. Avoid
      `nix.settings.auto-optimise-store` for now because it adds work to
      individual builds.

- [x] Binary cache policy: keep the default `cache.nixos.org` substituter and
      trusted public key only.

- [x] SSH access: regular OpenSSH is enabled on Desktop with key-only login.
      Port 22 is allowed only on the Tailscale interface; the public firewall
      remains closed.

- [x] Local service discovery: do not add explicit Avahi/mDNS settings for now.
      Remote development and personal services use Tailscale, while LAN
      discovery should be revisited only when a concrete printer, scanner, NAS,
      or `.local` hostname workflow needs it.

- [x] Bluetooth: enabled at the OS level and managed through GNOME.

- [x] Printing and scanning: keep only CUPS printing enabled for now. Add
      driverless/AirPrint discovery, device-specific drivers, or scanner support
      such as SANE/AirScan when an actual device needs it.

- [x] Japanese input method: use the standard Fcitx5 + Mozc stack at the NixOS
      layer. Hazkey remains deferred until it can be configured cleanly.

- [x] Desktop power behavior: keep automatic suspend disabled on AC. If
      suspend/resume still shows issues, investigate NVIDIA/systemd resume
      behavior separately.

- [x] Container runtime: enable the standard Podman setup with Docker CLI
      compatibility and DNS on the default Podman network for Compose-style
      service discovery. Keep Docker socket compatibility disabled unless a
      concrete tool such as Dev Containers or Testcontainers requires it.

- [ ] Virtualization: decide whether to enable libvirt, QEMU/KVM, VirtualBox, or
      none.

- [ ] Secrets management: decide whether to introduce `sops-nix`, `agenix`, or
      leave secrets outside this repository for now.

- [x] Polkit integration: Niri enables polkit, its session starts a GTK
      authentication agent, and 1Password grants its policy to `rheotommy`.

- [ ] Security baseline: review the sudo/wheel policy.

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
