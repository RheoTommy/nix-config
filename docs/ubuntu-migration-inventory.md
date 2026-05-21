# Ubuntu Migration Inventory

Snapshot time: 2026-05-21 17:34 JST.

Purpose: record what exists on the current Ubuntu laptop before rebuilding the
machine as NixOS. Secret values are intentionally not copied here. Sensitive
paths are listed as preservation targets only.

## Classification

- **System**: belongs in NixOS configuration because it affects hardware,
  services, boot, networking, users/groups, kernel support, system daemons, or
  machine-wide permissions.
- **Home Manager**: belongs to the user environment: shell, CLI tools, editor
  settings, GNOME dconf preferences, per-user services, application config, and
  dotfiles.
- **Secrets**: should be restored manually or managed by a secret tool such as
  `sops-nix`; do not put plaintext values in the Nix store or this repository.
- **Backup**: durable user data that should be copied before reinstall.
- **Rebuildable**: caches, downloaded toolchains, generated build artifacts, or
  application installs that are usually better recreated from declarative config.

## Host And Hardware

| Item | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| OS | Ubuntu 25.10 `questing` | New `hosts/<laptop>/` NixOS host |
| Hostname | `Ubuntu-Laptop` | **System**: choose final hostname |
| Machine | Lenovo ThinkPad T14s Gen 3, product `21CQCTO1WW` | **System**: laptop-specific host |
| Firmware | `R22ET80W (1.50 )` | **System**: note for hardware debugging |
| CPU | AMD Ryzen 7 PRO 6850U, 8C/16T | **System**: AMD laptop defaults |
| GPU | AMD Radeon 680M | **System**: Mesa/AMD graphics, no NVIDIA path |
| Wi-Fi | Qualcomm QCNFA765 | **System**: NetworkManager, firmware |
| Disk | KIOXIA Exceria Pro NVMe | **System**: generated hardware config |
| RAM/swap | 29 GiB RAM, 8 GiB swap | **System**: swap decision |

## Storage And Boot

| Item | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Root filesystem | `/dev/nvme0n1p5`, ext4, 384G total, 319G used, 46G free | **System**: new NixOS partition/layout |
| EFI | `/dev/nvme0n1p1`, vfat, mounted at `/boot/efi` | **System**: bootloader config |
| Windows partitions | `nvme0n1p3` NTFS `Windows`, `nvme0n1p4` `WinRE_DRV` | **System/Backup**: preserve if dual-boot remains |
| fstab | root by UUID, `/boot/efi` by UUID, `/swap.img` swap | **System**: regenerate, do not blindly copy |
| Space pressure | `/` is 88% used | **Backup/Rebuildable**: prune caches before migration if needed |

Large home directories:

| Path | Size | Classification |
| --- | ---: | --- |
| `/home/rheotommy/.local` | 78G | mixed; mostly **Rebuildable** tool/app installs |
| `/home/rheotommy/.local/share/JetBrains` | 64G | **Rebuildable**, unless IDE state is important |
| `/home/rheotommy/.ghcup` | 25G | **Rebuildable/Home Manager** Haskell toolchain decision |
| `/home/rheotommy/.local/share/mise` | 10G | **Rebuildable/Home Manager** from mise config |
| `/home/rheotommy/.npm` | 8.2G | **Rebuildable** |
| `/home/rheotommy/Downloads` | 5.7G | **Backup**, user-selected |
| `/home/rheotommy/.config` | 5.3G | **Home Manager/Backup**, inspect before pruning |
| `/home/rheotommy/go` | 4.9G | **Backup/Rebuildable**, depends on source vs cache |
| `/home/rheotommy/snap` | 4.6G | **Backup/Rebuildable**, Snap app user state |
| `/home/rheotommy/Projects` | 3.9G | **Backup** |
| `/home/rheotommy/.var` | 3.4G | **Backup**, Flatpak app state |
| `/home/rheotommy/.cache` | 3.1G | **Rebuildable** |
| `/home/rheotommy/.steam` | 2.6G | **Backup/Rebuildable**, game data decision |

## Package Surfaces

| Surface | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| APT | 3247 installed packages, 155 manual packages | Split into **System** services and **Home Manager** tools |
| APT extra repos | 1Password, Tailscale, Antigravity | Prefer Nixpkgs/flake inputs; avoid distro repo carryover |
| Snap | 53 snap files observed; `snap list` was blocked by sandbox socket access | Prefer Nixpkgs/Flatpak/Home Manager replacements |
| Flatpak | Logseq, Slack, Bottles, Obsidian | **Home Manager** or Flatpak policy later |
| Nix | `/nix` exists, Nix 2.34.6, but `nix` is not on PATH in this shell | Replace with NixOS native Nix; clean installer remnants after reinstall |
| mise | installed under `~/.local/bin`, active tool pins listed below | **Home Manager** if keeping mise |
| Rustup/Cargo | stable toolchain, cargo-installed binaries | **Home Manager** or project-local devshells |
| VS Code | deb `code`, many extensions | **Home Manager** or manual editor sync |
| JetBrains Toolbox | large user install under `.local/share/JetBrains` | **Home Manager/Backup**; likely reinstall rather than copy binaries |

Notable manual APT packages to classify later:

- **System candidates**: `tailscale`, `docker-ce`, `containerd.io`,
  `docker-compose-plugin`, `virtualbox`, `virtualbox-dkms`, `qemu-system-x86`,
  `libvirtd`, `cups`, `cups-browsed`, `sane-airscan`, `fprintd`, `fwupd`,
  `thermald`, `power-profiles-daemon`, `input-remapper`, `openvpn`, `f5vpn`,
  `steam:i386`, `wine`, `wine32:i386`, `wine64`, `winetricks`.
- **Home Manager candidates**: `zsh`, `tmux`, `zoxide`, `direnv`, `git`, `glab`,
  `gh` via mise, `jq`, `wl-clipboard`, `xsel`, `xdotool`, `wmctrl`, `ncdu`,
  `gimp`, `google-chrome-stable`, `code`, `zoom`, `quarto`.
- **Development toolchains**: multiple `clang`/`gcc` versions, `cmake`,
  `protobuf-compiler`, `ruby`, `python3-full`, `yosys`, `iverilog`, OpenCL
  headers/dev packages.
- **Input/i18n**: `fcitx5`, `fcitx5-hazkey`, `ibus-mozc`, `mozc-utils-gui`,
  Japanese language packs and CJK fonts.

## System Services

| Area | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Desktop | GNOME 49 / GDM enabled | **System**: GNOME/GDM laptop host |
| Audio | PipeWire user services enabled | **System**: PipeWire |
| Network | NetworkManager enabled | **System** |
| Tailscale | `tailscaled.service` enabled; self IP `100.86.79.110` | **System**: Tailscale on laptop |
| Firewall | `ufw.conf` says `ENABLED=no` | **System**: NixOS firewall defaults |
| Docker | `docker.service`, `docker.socket`, `containerd.service` enabled | **System**: decide Docker vs Podman compatibility |
| libvirt/QEMU | `libvirtd`, `virtlogd`, `virtlockd`, `qemu-kvm` enabled | **System**: decide virtualization stack |
| VirtualBox | installed, user in `vboxusers`; `VBoxManage` reports driver/COM problem | **System**: likely do not migrate unless needed |
| Printing/scanning | CUPS, `cups-browsed`, SANE/AirScan packages | **System**: only if devices need it |
| Bluetooth | `bluetooth.service` enabled | **System** |
| Firmware | `fwupd-refresh.timer` enabled | **System**: fwupd if desired |
| Power | `power-profiles-daemon`, `thermald`, `switcheroo-control` enabled | **System**: laptop power policy |
| Fingerprint | `fprintd` installed | **System**: decide fingerprint support |
| Avahi/mDNS | `avahi-daemon` enabled | **System**: only if LAN discovery needed |
| Cloud-init | cloud-init services enabled | Probably **not migrated** |
| SSSD | SSSD units enabled | Probably **not migrated** unless actually used |

Enabled user services:

| Service | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| PipeWire/WirePlumber | enabled | **System** provides service, user session runs it |
| GNOME keyring / gcr SSH agent | enabled | **Home Manager/System**, decide SSH agent strategy |
| `logseq-sync.timer` | every 10 minutes, calls `%h/.local/bin/logseq-sync.sh` | **Home Manager**, if still wanted |
| `fig-daemon.service` | calls `/usr/bin/fig daemon` | likely **not migrated** unless Fig is still used |

## Network

| Item | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Active LAN | Wi-Fi `wlp1s0`, currently on `192.168.3.22/24` | **System**: NetworkManager |
| Tailnet | `tailscale0`, `100.86.79.110/32` | **System** |
| Docker bridges | `docker0` and several `br-*` networks | **System/Rebuildable** from container runtime |
| Saved Wi-Fi | Many NetworkManager profiles observed by name | **Secrets**: passwords should not be committed plaintext |
| Netplan | many `90-NM-*.yaml` generated files plus `50-cloud-init.yaml` | **System**: do not copy directly; recreate with NetworkManager |
| Tailscale health | reported DNS reachability warning | **System**: verify after NixOS migration |

If Wi-Fi profiles must be declarative, use a secret-management workflow for
passwords. Do not put PSKs in a public or unencrypted flake.

## Input, Locale, Desktop Preferences

| Area | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Locale | `/etc/default/locale`: `LANG=ja_JP.UTF-8` | **System**: repo currently prefers English UI + JP locale categories |
| Keyboard | `/etc/default/keyboard`: `us`, no variant | **System** |
| GNOME input source | `xkb us`, `caps:hyper` | **Home Manager** dconf, or NixOS xkb option for system-level |
| GNOME fonts | Noto CJK UI fonts, PlemolJP monospace | **System fonts** + **Home Manager dconf** |
| GNOME shell extensions | Dash to Panel, Tiling Shell, DING, AppIndicator, User Theme, notification banner | **Home Manager** if managed declaratively |
| GNOME favorites | Chrome apps, Logseq, Spotify, Ptyxis, Nautilus, Slack, Discord, Code, JetBrains Toolbox | **Home Manager** dconf |
| GNOME power | idle delay 900s; AC inactive type `nothing` | **Home Manager** dconf for user session; **System** for GDM/host policy |
| Mouse/touchpad | custom speed, two-finger scroll, fingers click method | **Home Manager** dconf |
| Terminal | Ptyxis and GNOME Terminal use PlemolJP and i-beam cursor | **Home Manager** |

Fcitx5/Hazkey state:

| Item | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Fcitx5 profile | default IM is `hazkey`, with `keyboard-us` fallback | **System package** + **Home Manager config** |
| Fcitx5 trigger | `Control+space`, `Zenkaku_Hankaku`, `Hangul` | **Home Manager** |
| Hazkey config | Zenzai enabled, backend device `Vulkan0`, contextual mode enabled | **Home Manager**, host-specific GPU/device setting |
| Zenzai model | `~/.local/share/hazkey/zenzai/zenzai.gguf` | **Backup/Rebuildable**, depending on packaging |
| Custom keymap | `l` maps to `ー` | **Home Manager**, easy to declaratively generate |

Input-remapper state exists for ThinkPad extra buttons, multiple keyboards, and
an ELECOM trackball. This is **System** for daemon/package/device access and
**Home Manager/Backup** for per-device preset files.

## Development Environment

Current mise config:

```toml
[tools]
"cargo:ripgrep" = "latest"
gh = "latest"
jujutsu = "latest"
node = "latest"
"npm:@anthropic-ai/sandbox-runtime" = "latest"
"npm:@google/gemini-cli" = "latest"
"npm:@openai/codex" = "latest"
"npm:ccusage" = "latest"
pnpm = "10.12.1"
python = "latest"
watchexec = "latest"
zellij = "latest"

[settings]
experimental = true
idiomatic_version_file_enable_tools = ["python"]
```

Current resolved versions include `gh 2.92.0`, `jujutsu 0.41.0`, `node 25.8.2`,
`pnpm 10.12.1`, `python 3.12.7`, `zellij 0.44.3`, and Codex `0.130.0`.

Shell/dotfile state:

| Item | Current Ubuntu state | NixOS target |
| --- | --- | --- |
| Login shell | `/usr/bin/zsh` | **System**: user shell; **Home Manager**: zsh config |
| zsh plugins | Sheldon manages completions, syntax highlighting, starship | **Home Manager** |
| PATH | mise shims, `.local/bin`, Cargo, GCloud SDK, Pulumi, GHCup, JetBrains Toolbox | **Home Manager** |
| aliases | `ls=eza --icons --git`, `tree=tre`, `clip=xsel --clipboard --input` | **Home Manager** |
| Git | name/email, `delta` pager, `zdiff3`, gh/glab credential helpers | **Home Manager**, auth tokens as **Secrets** |
| jj | user name/email, `spr` alias to `jj-spr` | **Home Manager** |
| Zellij | custom keybind-heavy generated config | **Home Manager** |

Cargo-installed binaries recorded in `.cargo/.crates.toml`: `bat`, `eza`,
`git-delta`, `grcov`, `jj-spr`, `md_to_report`, `sheldon`, `tokei`, `tre`,
`treemd`.

VS Code extensions include Nix, Dev Containers, Docker/Containers, GitHub
Actions, Copilot Chat, Python/Jupyter, C/C++, Go, Haskell, Racket, Typst,
Quarto, Marp, Markdown, PDF, GitLens, Git Graph, and JetBrains keymap/icon
extensions. This is **Home Manager** if managed declaratively, otherwise editor
sync/manual reinstall.

## Containers And Virtualization

Docker is heavily used on Ubuntu:

| Docker item | Current state |
| --- | --- |
| Images | 117 total, 52.41GB, 44.74GB reclaimable |
| Containers | 20 total, 1 active |
| Volumes | 235 total, 5.86GB |
| Build cache | 452 entries, 42.8GB reclaimable |
| Active container | `buildx_buildkit_multiarch0` |

Observed workloads include buildx, GitHub Actions `act`, LocalStack, DynamoDB
Admin, Supabase, CDK assets, Marubeni app containers, devcontainer helpers, and
project images. Most images and build cache are **Rebuildable**. Named Docker
volumes may contain durable local databases and should be inspected before
discarding.

NixOS migration choices:

- **System**: choose Podman-only, Docker-only, or Podman with Docker socket
  compatibility.
- **Backup/Secrets**: inspect Docker volumes that correspond to real local data.
- **Rebuildable**: images, stopped CI containers, buildx cache, `act` leftovers.

libvirt is enabled but has no listed VMs. VirtualBox is installed but
`VBoxManage list vms` failed because the VirtualBox driver/COM server is not
working in the current environment. Treat VirtualBox as **not worth migrating**
unless there are actual VM files outside this command's visibility.

## Applications And User Data

Likely user-data preservation targets:

- `~/Projects`
- `~/Documents`
- `~/Downloads`, after manual cleanup
- `~/Pictures`, `~/Music`, `~/Videos`
- `~/.ssh`
- `~/.gnupg`
- `~/.aws`
- `~/.config/gh`, `~/.config/glab-cli`, `~/.local/share/gh`
- `~/.config/gcloud`, `~/google-cloud-sdk`
- `~/.config/1Password`, `~/.local/share/keyrings`
- browser profiles: `~/.config/google-chrome`, plus any Brave/Vivaldi/Chromium
  profiles still needed
- `~/.config/Logseq`, `~/.logseq`, Flatpak state under `~/.var`
- JetBrains config under `~/.config/JetBrains`; large app binaries under
  `~/.local/share/JetBrains` are probably rebuildable
- `~/.config/Code` and `~/.vscode`, if not relying on Settings Sync
- `~/.steam`, `~/.wine`, Bottles/Flatpak state if gaming or Windows apps matter

Known secret-bearing paths:

- `~/.ssh/id_*`
- `~/.gnupg`
- `~/.aws`
- `~/.config/gh`, `~/.config/glab-cli`
- `~/.config/gcloud`
- `~/.codex/auth.json` if present
- `~/.config/1Password`, GNOME keyrings
- NetworkManager / netplan Wi-Fi credentials
- Docker/Compose project `.env` files and local volumes

## Nix Remnants

Ubuntu currently has a partial Nix install:

- `/nix` exists and is about 2.5G.
- `/nix/var/nix/profiles/default/bin/nix` is Nix 2.34.6.
- `nix` was not found on PATH in this shell.
- `/etc/nix/nix.conf` was generated by `nix-installer`, with flakes enabled,
  `auto-optimise-store = true`, and `always-allow-substitutes = true`.
- `/etc/profile.d/nix.sh` contains duplicated Nix profile hooks.
- `~/.profile` and `~/.zshenv` still reference `~/.nix-profile`, which does not
  exist.
- `~/.config/nixpkgs/home-manager` contains an old Home Manager flake.

For NixOS, this should not be migrated directly. Recreate Nix/Home Manager from
this repository and clean these Ubuntu-specific remnants during reinstall.

## Proposed Migration Mapping

| Category | Ubuntu evidence | Move to |
| --- | --- | --- |
| Laptop hardware, boot, firmware, AMD GPU, Wi-Fi, Bluetooth | DMI, `lspci`, `lsblk` | `hosts/<laptop>/` **System** |
| NetworkManager, Tailscale, firewall defaults | enabled services, nmcli state | **System** |
| GNOME/GDM, PipeWire, CUPS, fwupd, power profiles | enabled services | **System** common or laptop host |
| Docker/Podman/libvirt/VirtualBox | Docker active, libvirt enabled, VirtualBox broken | **System** decision per host |
| Fcitx5/Hazkey packages | APT packages, Fcitx5 profile | **System** package + **Home Manager** config |
| Hazkey profile, Zenzai, keymap `l -> ー` | user config files | **Home Manager**, host-specific device |
| Shell, git, jj, zellij, mise, VS Code extensions | dotfiles and user tool config | **Home Manager** |
| App installs like Chrome, Slack, Obsidian, Logseq, JetBrains | APT/Snap/Flatpak/user dirs | mostly **Home Manager** or manual app policy |
| Credentials and Wi-Fi passwords | secret-bearing paths | **Secrets** |
| Projects, documents, browser profiles, Logseq, keyrings | user dirs | **Backup** |
| `.cache`, Docker images/build cache, npm/mise/ghcup tool downloads | size inventory | **Rebuildable** unless specifically needed |

## Open Follow-Ups

- Decide whether laptop should use `nixos-hardware` for ThinkPad T14s Gen 3.
- Decide whether this laptop should use Podman like Desktop, Docker for maximum
  Dev Containers compatibility, or both via Podman Docker socket compatibility.
- Decide whether to introduce `sops-nix` before declaring Wi-Fi or Tailscale auth
  material.
- Decide how much of GNOME/dconf should be declarative versus manually adjusted
  after install.
- Inspect Docker volumes before deleting Ubuntu; some may contain local DB state.
- Decide whether `input-remapper`, fingerprint login, VirtualBox, libvirt, Wine,
  Steam, and Bottles are actually still needed on the laptop.
