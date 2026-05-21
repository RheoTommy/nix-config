# Ubuntu 移行インベントリ

スナップショット時刻: 2026-05-21 17:34 JST。

目的: 現在の Ubuntu laptop を NixOS として作り直す前に、このマシンに何が存在するかを記録する。secret の値は意図的にコピーしていない。機密性のあるパスは、保存対象としてのみ列挙する。

## 分類

- **System**: ハードウェア、service、boot、networking、users/groups、kernel support、system daemon、machine-wide permission に関わるため、NixOS configuration に置くもの。
- **Home Manager**: shell、CLI tool、editor 設定、GNOME dconf preference、per-user service、application config、dotfiles など、ユーザー環境に属するもの。
- **Secrets**: 手動復元するか、`sops-nix` などの secret 管理で扱うもの。平文を Nix store やこの repository に置かない。
- **Backup**: 再インストール前にコピーすべき永続的なユーザーデータ。
- **Rebuildable**: cache、download 済み toolchain、生成済み build artifact、application install など、宣言的な設定から再生成する方がよいもの。

## Host と Hardware

| 項目 | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| OS | Ubuntu 25.10 `questing` | 新しい `hosts/<laptop>/` NixOS host |
| Hostname | `Ubuntu-Laptop` | **System**: 最終 hostname を決める |
| Machine | Lenovo ThinkPad T14s Gen 3, product `21CQCTO1WW` | **System**: laptop 固有 host |
| Firmware | `R22ET80W (1.50 )` | **System**: hardware debug 用に記録 |
| CPU | AMD Ryzen 7 PRO 6850U, 8C/16T | **System**: AMD laptop defaults |
| GPU | AMD Radeon 680M | **System**: Mesa/AMD graphics。NVIDIA 設定は不要 |
| Wi-Fi | Qualcomm QCNFA765 | **System**: NetworkManager と firmware |
| Disk | KIOXIA Exceria Pro NVMe | **System**: hardware config を生成 |
| RAM/swap | 29 GiB RAM, 8 GiB swap | **System**: swap 方針を決める |

## Storage と Boot

| 項目 | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Root filesystem | `/dev/nvme0n1p5`, ext4, 384G total, 319G used, 46G free | **System**: 新しい NixOS partition/layout |
| EFI | `/dev/nvme0n1p1`, vfat, `/boot/efi` に mount | **System**: bootloader config |
| Windows partitions | `nvme0n1p3` NTFS `Windows`, `nvme0n1p4` `WinRE_DRV` | **System/Backup**: dual-boot を残すなら保持 |
| fstab | root by UUID, `/boot/efi` by UUID, `/swap.img` swap | **System**: 再生成する。丸ごとコピーしない |
| 容量逼迫 | `/` は 88% used | **Backup/Rebuildable**: 移行前に cache を prune する余地あり |

大きい home directory:

| Path | Size | Classification |
| --- | ---: | --- |
| `/home/rheotommy/.local` | 78G | mixed。多くは tool/app install なので **Rebuildable** |
| `/home/rheotommy/.local/share/JetBrains` | 64G | IDE state が重要でなければ **Rebuildable** |
| `/home/rheotommy/.ghcup` | 25G | **Rebuildable/Home Manager**。Haskell toolchain 方針次第 |
| `/home/rheotommy/.local/share/mise` | 10G | mise config から **Rebuildable/Home Manager** |
| `/home/rheotommy/.npm` | 8.2G | **Rebuildable** |
| `/home/rheotommy/Downloads` | 5.7G | **Backup**。手動で取捨選択 |
| `/home/rheotommy/.config` | 5.3G | **Home Manager/Backup**。prune 前に確認 |
| `/home/rheotommy/go` | 4.9G | source か cache かにより **Backup/Rebuildable** |
| `/home/rheotommy/snap` | 4.6G | Snap app user state。**Backup/Rebuildable** |
| `/home/rheotommy/Projects` | 3.9G | **Backup** |
| `/home/rheotommy/.var` | 3.4G | Flatpak app state。**Backup** |
| `/home/rheotommy/.cache` | 3.1G | **Rebuildable** |
| `/home/rheotommy/.steam` | 2.6G | game data 方針次第で **Backup/Rebuildable** |

## Package Surface

| Surface | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| APT | 3247 installed packages, 155 manual packages | **System** services と **Home Manager** tools に分ける |
| APT extra repos | 1Password, Tailscale, Antigravity | Nixpkgs/flake inputs を優先。distro repo は持ち込まない |
| Snap | 53 snap files observed。`snap list` は sandbox の socket 制約で blocked | Nixpkgs/Flatpak/Home Manager replacement を優先 |
| Flatpak | Logseq, Slack, Bottles, Obsidian | **Home Manager** または Flatpak policy を後で決める |
| Nix | `/nix` が存在し、Nix 2.34.6。ただしこの shell では `nix` が PATH にない | NixOS native Nix に置き換える。Ubuntu installer remnants は移行後に cleanup |
| mise | `~/.local/bin` 配下にあり、active tool pins は下記 | mise を継続するなら **Home Manager** |
| Rustup/Cargo | stable toolchain、cargo-installed binaries | **Home Manager** または project-local devshell |
| VS Code | deb `code`、多数の extensions | **Home Manager** または editor sync/manual reinstall |
| JetBrains Toolbox | `.local/share/JetBrains` 配下に大きい user install | **Home Manager/Backup**。binary は再 install が妥当 |

後で分類すべき主な manual APT packages:

- **System candidates**: `tailscale`, `docker-ce`, `containerd.io`, `docker-compose-plugin`, `virtualbox`, `virtualbox-dkms`, `qemu-system-x86`, `libvirtd`, `cups`, `cups-browsed`, `sane-airscan`, `fprintd`, `fwupd`, `thermald`, `power-profiles-daemon`, `input-remapper`, `openvpn`, `f5vpn`, `steam:i386`, `wine`, `wine32:i386`, `wine64`, `winetricks`。
- **Home Manager candidates**: `zsh`, `tmux`, `zoxide`, `direnv`, `git`, `glab`, mise 経由の `gh`, `jq`, `wl-clipboard`, `xsel`, `xdotool`, `wmctrl`, `ncdu`, `gimp`, `google-chrome-stable`, `code`, `zoom`, `quarto`。
- **Development toolchains**: 複数の `clang`/`gcc` versions、`cmake`, `protobuf-compiler`, `ruby`, `python3-full`, `yosys`, `iverilog`, OpenCL headers/dev packages。
- **Input/i18n**: `fcitx5`, `fcitx5-hazkey`, `ibus-mozc`, `mozc-utils-gui`, Japanese language packs, CJK fonts。

## System Services

| Area | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Desktop | GNOME 49 / GDM enabled | **System**: GNOME/GDM laptop host |
| Audio | PipeWire user services enabled | **System**: PipeWire |
| Network | NetworkManager enabled | **System** |
| Tailscale | `tailscaled.service` enabled。self IP `100.86.79.110` | **System**: laptop でも Tailscale |
| Firewall | `ufw.conf` は `ENABLED=no` | **System**: NixOS firewall defaults |
| Docker | `docker.service`, `docker.socket`, `containerd.service` enabled | **System**: Docker vs Podman compatibility を決める |
| libvirt/QEMU | `libvirtd`, `virtlogd`, `virtlockd`, `qemu-kvm` enabled | **System**: virtualization stack を決める |
| VirtualBox | installed。user は `vboxusers`。`VBoxManage` は driver/COM problem を報告 | **System**: 必要でなければ移行しない |
| Printing/scanning | CUPS, `cups-browsed`, SANE/AirScan packages | **System**: 実デバイスが必要なら有効化 |
| Bluetooth | `bluetooth.service` enabled | **System** |
| Firmware | `fwupd-refresh.timer` enabled | **System**: fwupd を使うなら |
| Power | `power-profiles-daemon`, `thermald`, `switcheroo-control` enabled | **System**: laptop power policy |
| Fingerprint | `fprintd` installed | **System**: fingerprint support を決める |
| Avahi/mDNS | `avahi-daemon` enabled | **System**: LAN discovery が必要な場合のみ |
| Cloud-init | cloud-init services enabled | 基本的に **not migrated** |
| SSSD | SSSD units enabled | 実際に使っていなければ **not migrated** |

Enabled user services:

| Service | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| PipeWire/WirePlumber | enabled | **System** が service を提供し、user session で動く |
| GNOME keyring / gcr SSH agent | enabled | **Home Manager/System**。SSH agent 方針を決める |
| `logseq-sync.timer` | 10分ごとに `%h/.local/bin/logseq-sync.sh` を実行 | 継続するなら **Home Manager** |
| `fig-daemon.service` | `/usr/bin/fig daemon` を実行 | Fig を継続しないなら移行しない |

## Network

| 項目 | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Active LAN | Wi-Fi `wlp1s0`, currently `192.168.3.22/24` | **System**: NetworkManager |
| Tailnet | `tailscale0`, `100.86.79.110/32` | **System** |
| Docker bridges | `docker0` と複数の `br-*` networks | container runtime から **System/Rebuildable** |
| Saved Wi-Fi | 多数の NetworkManager profile 名を確認 | **Secrets**: password は平文 commit しない |
| Netplan | 多数の `90-NM-*.yaml` generated files と `50-cloud-init.yaml` | **System**: 直接コピーせず NetworkManager で再作成 |
| Tailscale health | DNS reachability warning が報告されている | **System**: NixOS 移行後に確認 |

Wi-Fi profile を宣言的に管理する場合は、password を secret 管理に載せる。PSK を公開 flake や暗号化なし repository に置かない。

## Input, Locale, Desktop Preferences

| Area | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Locale | `/etc/default/locale`: `LANG=ja_JP.UTF-8` | **System**: この repo では English UI + JP locale categories 方針 |
| Keyboard | `/etc/default/keyboard`: `us`, no variant | **System** |
| GNOME input source | `xkb us`, `caps:hyper` | **Home Manager** dconf、または system-level なら NixOS xkb option |
| GNOME fonts | Noto CJK UI fonts, PlemolJP monospace | **System fonts** + **Home Manager dconf** |
| GNOME shell extensions | Dash to Panel, Tiling Shell, DING, AppIndicator, User Theme, notification banner | 宣言管理するなら **Home Manager** |
| GNOME favorites | Chrome apps, Logseq, Spotify, Ptyxis, Nautilus, Slack, Discord, Code, JetBrains Toolbox | **Home Manager** dconf |
| GNOME power | idle delay 900s。AC inactive type `nothing` | user session は **Home Manager** dconf。GDM/host policy は **System** |
| Mouse/touchpad | custom speed, two-finger scroll, fingers click method | **Home Manager** dconf |
| Terminal | Ptyxis と GNOME Terminal が PlemolJP と i-beam cursor を使用 | **Home Manager** |

Fcitx5/Hazkey state:

| 項目 | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Fcitx5 profile | default IM は `hazkey`、fallback は `keyboard-us` | **System package** + **Home Manager config** |
| Fcitx5 trigger | `Control+space`, `Zenkaku_Hankaku`, `Hangul` | **Home Manager** |
| Hazkey config | Zenzai enabled、backend device `Vulkan0`、contextual mode enabled | **Home Manager**。host-specific GPU/device setting |
| Zenzai model | `~/.local/share/hazkey/zenzai/zenzai.gguf` | packaging 方針次第で **Backup/Rebuildable** |
| Custom keymap | `l` maps to `ー` | **Home Manager**。宣言的生成しやすい |

input-remapper state は、ThinkPad extra buttons、複数 keyboard、ELECOM trackball の preset を持つ。daemon/package/device access は **System**、per-device preset files は **Home Manager/Backup**。

## Development Environment

現在の mise config:

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

現在解決されている versions は `gh 2.92.0`, `jujutsu 0.41.0`, `node 25.8.2`, `pnpm 10.12.1`, `python 3.12.7`, `zellij 0.44.3`, Codex `0.130.0`。

Shell/dotfile state:

| 項目 | 現在の Ubuntu 状態 | NixOS での扱い |
| --- | --- | --- |
| Login shell | `/usr/bin/zsh` | **System**: user shell。**Home Manager**: zsh config |
| zsh plugins | Sheldon が completions, syntax highlighting, starship を管理 | **Home Manager** |
| PATH | mise shims, `.local/bin`, Cargo, GCloud SDK, Pulumi, GHCup, JetBrains Toolbox | **Home Manager** |
| aliases | `ls=eza --icons --git`, `tree=tre`, `clip=xsel --clipboard --input` | **Home Manager** |
| Git | name/email, `delta` pager, `zdiff3`, gh/glab credential helpers | **Home Manager**。auth tokens は **Secrets** |
| jj | user name/email, `spr` alias to `jj-spr` | **Home Manager** |
| Zellij | keybind が多い generated config | **Home Manager** |

`.cargo/.crates.toml` に記録されている cargo-installed binaries: `bat`, `eza`, `git-delta`, `grcov`, `jj-spr`, `md_to_report`, `sheldon`, `tokei`, `tre`, `treemd`。

VS Code extensions は Nix、Dev Containers、Docker/Containers、GitHub Actions、Copilot Chat、Python/Jupyter、C/C++、Go、Haskell、Racket、Typst、Quarto、Marp、Markdown、PDF、GitLens、Git Graph、JetBrains keymap/icon など。宣言的に管理するなら **Home Manager**。そうでなければ editor sync/manual reinstall。

## Containers と Virtualization

Ubuntu では Docker がかなり使われている:

| Docker item | Current state |
| --- | --- |
| Images | 117 total, 52.41GB, 44.74GB reclaimable |
| Containers | 20 total, 1 active |
| Volumes | 235 total, 5.86GB |
| Build cache | 452 entries, 42.8GB reclaimable |
| Active container | `buildx_buildkit_multiarch0` |

観測された workload は buildx、GitHub Actions `act`、LocalStack、DynamoDB Admin、Supabase、CDK assets、Marubeni app containers、devcontainer helpers、project images など。images と build cache の大半は **Rebuildable**。named Docker volumes には local DB state が入っている可能性があるため、破棄前に確認する。

NixOS migration choices:

- **System**: Podman-only、Docker-only、または Podman with Docker socket compatibility を選ぶ。
- **Backup/Secrets**: 実データに対応する Docker volumes を確認する。
- **Rebuildable**: images、停止済み CI containers、buildx cache、`act` leftovers。

libvirt は enabled だが、listed VMs はない。VirtualBox は installed だが、`VBoxManage list vms` は VirtualBox driver/COM server の問題で失敗した。実際の VM files が別途存在しない限り、VirtualBox は **移行しない候補** として扱う。

## Applications と User Data

保存対象になりそうな user data:

- `~/Projects`
- `~/Documents`
- `~/Downloads`。手動 cleanup 後
- `~/Pictures`, `~/Music`, `~/Videos`
- `~/.ssh`
- `~/.gnupg`
- `~/.aws`
- `~/.config/gh`, `~/.config/glab-cli`, `~/.local/share/gh`
- `~/.config/gcloud`, `~/google-cloud-sdk`
- `~/.config/1Password`, `~/.local/share/keyrings`
- browser profiles: `~/.config/google-chrome`。必要なら Brave/Vivaldi/Chromium profiles も
- `~/.config/Logseq`, `~/.logseq`, Flatpak state under `~/.var`
- JetBrains config under `~/.config/JetBrains`。大きい app binaries under `~/.local/share/JetBrains` は probably rebuildable
- `~/.config/Code`, `~/.vscode`。Settings Sync に任せない場合
- `~/.steam`, `~/.wine`, Bottles/Flatpak state。gaming や Windows apps が重要な場合

secret を含みうる既知の paths:

- `~/.ssh/id_*`
- `~/.gnupg`
- `~/.aws`
- `~/.config/gh`, `~/.config/glab-cli`
- `~/.config/gcloud`
- `~/.codex/auth.json` if present
- `~/.config/1Password`, GNOME keyrings
- NetworkManager / netplan Wi-Fi credentials
- Docker/Compose project `.env` files and local volumes

## Nix の残骸

Ubuntu には partial Nix install が存在する:

- `/nix` が存在し、約 2.5G。
- `/nix/var/nix/profiles/default/bin/nix` は Nix 2.34.6。
- この shell では `nix` が PATH にない。
- `/etc/nix/nix.conf` は `nix-installer` 生成。flakes enabled、`auto-optimise-store = true`、`always-allow-substitutes = true`。
- `/etc/profile.d/nix.sh` は Nix profile hook が重複している。
- `~/.profile` と `~/.zshenv` は、存在しない `~/.nix-profile` をまだ参照している。
- `~/.config/nixpkgs/home-manager` には古い Home Manager flake がある。

NixOS では、これを直接移行しない。この repository から Nix/Home Manager を再作成し、Ubuntu 固有の remnants は reinstall 時に cleanup する。

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
| Chrome, Slack, Obsidian, Logseq, JetBrains など app installs | APT/Snap/Flatpak/user dirs | mostly **Home Manager** or manual app policy |
| Credentials and Wi-Fi passwords | secret-bearing paths | **Secrets** |
| Projects, documents, browser profiles, Logseq, keyrings | user dirs | **Backup** |
| `.cache`, Docker images/build cache, npm/mise/ghcup tool downloads | size inventory | **Rebuildable** unless specifically needed |

## Open Follow-Ups

- laptop で ThinkPad T14s Gen 3 向け `nixos-hardware` を使うか決める。
- この laptop も Desktop と同様 Podman にするか、Dev Containers 互換性重視で Docker にするか、あるいは Podman Docker socket compatibility を使うか決める。
- Wi-Fi や Tailscale auth material を宣言管理する前に、`sops-nix` を導入するか決める。
- GNOME/dconf をどこまで宣言管理し、どこから install 後の手動調整にするか決める。
- Ubuntu を消す前に Docker volumes を確認する。一部に local DB state がある可能性がある。
- `input-remapper`、fingerprint login、VirtualBox、libvirt、Wine、Steam、Bottles が laptop に本当に必要か決める。
