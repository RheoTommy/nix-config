# NixOS と Home Manager の設定用 Flake

このリポジトリは、NixOS のシステム設定と Home Manager のユーザー設定を管理するための Flake です。NixOS と Home Manager の両方を独立して利用することができます。

## リポジトリの構造

```
.
├── flake.nix                  # メインの Flake 設定ファイル
├── home                       # Home Manager の設定
│   └── rheotommy              # ユーザー rheotommy の設定
│       └── default.nix        # rheotommy の Home Manager 設定
└── hosts                      # NixOS ホストの設定
    ├── hardware.nix           # 共通ハードウェア設定
    └── nixos-desktop          # nixos-desktop ホストの設定
        └── default.nix        # nixos-desktop の NixOS 設定
```

### 主要なファイル

- **flake.nix**: リポジトリのエントリーポイントです。NixOS と Home Manager の設定をエクスポートします。
- **hosts/nixos-desktop/default.nix**: nixos-desktop ホストの NixOS システム設定です。
- **hosts/hardware.nix**: ハードウェア固有の設定（ファイルシステム、カーネルモジュールなど）です。
- **home/rheotommy/default.nix**: ユーザー rheotommy の Home Manager 設定です。

## 使い方

### 前提条件

- NixOS がインストールされていること
- Flakes が有効化されていること（`nix.settings.experimental-features = [ "nix-command" "flakes" ];`）

### リポジトリのクローン

```bash
git clone https://github.com/yourusername/nix-config.git
cd nix-config
```

### NixOS の設定を適用する

このリポジトリの NixOS 設定を適用するには、以下のコマンドを実行します：

```bash
# リポジトリのルートディレクトリで実行
sudo nixos-rebuild switch --flake .#nixos-desktop
```

ここで `nixos-desktop` は flake.nix で定義されたホスト名です。別のホストを追加した場合は、そのホスト名を指定します。

### Home Manager の設定を適用する

#### NixOS の一部として Home Manager を使用する場合

NixOS の設定を適用すると、Home Manager の設定も自動的に適用されます：

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

#### スタンドアロンの Home Manager として使用する場合

Home Manager をスタンドアロンで使用する場合（NixOS 以外の Linux ディストリビューションや、別の NixOS システムなど）：

```bash
# リポジトリのルートディレクトリで実行
home-manager switch --flake .#rheotommy@nixos-desktop
```

ここで `rheotommy@nixos-desktop` は `ユーザー名@ホスト名` の形式です。

## 設定の更新方法

### NixOS の設定を更新する

1. 設定ファイルを編集します（例：`hosts/nixos-desktop/default.nix`）
2. 変更を適用します：

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

### Home Manager の設定を更新する

1. 設定ファイルを編集します（例：`home/rheotommy/default.nix`）
2. 変更を適用します：

```bash
# NixOS の一部として Home Manager を使用している場合
sudo nixos-rebuild switch --flake .#nixos-desktop

# または、スタンドアロンの Home Manager として使用している場合
home-manager switch --flake .#rheotommy@nixos-desktop
```

## 新しいホストの追加方法

新しいホストを追加するには：

1. `hosts/` ディレクトリに新しいホスト用のディレクトリを作成します：
   ```bash
   mkdir -p hosts/new-host
   ```

2. 新しいホストの設定ファイルを作成します：
   ```bash
   # 基本的な設定を生成（オプション）
   nixos-generate-config --dir hosts/new-host
   # または既存の設定をコピーして編集
   cp hosts/nixos-desktop/default.nix hosts/new-host/
   ```

3. `flake.nix` を編集して新しいホストを追加します：
   ```text
   nixosConfigurations."new-host" = nixpkgs.lib.nixosSystem {
     inherit system;
     inherit specialArgs;
     modules = [
       ./hosts/new-host/default.nix
       # その他のモジュール
     ];
   };
   ```

## 新しいユーザーの追加方法

新しいユーザーを追加するには：

1. `home/` ディレクトリに新しいユーザー用のディレクトリを作成します：
   ```bash
   mkdir -p home/newuser
   ```

2. 新しいユーザーの Home Manager 設定ファイルを作成します：
   ```bash
   cp home/rheotommy/default.nix home/newuser/
   # 設定を編集して新しいユーザーに合わせます
   ```

3. `flake.nix` の Home Manager 設定を編集して新しいユーザーを追加します：
   ```text
   home-manager = {
     # 既存の設定...
     users."newuser" = import ./home/newuser/default.nix;
   };
   ```

## トラブルシューティング

### ビルドエラーが発生する場合

設定に問題がある場合は、まずドライランを実行して詳細なエラーメッセージを確認します：

```bash
# NixOS の場合
nixos-rebuild build --flake .#nixos-desktop

# Home Manager の場合
home-manager build --flake .#rheotommy@nixos-desktop
```

### 以前の設定に戻す

問題が発生した場合は、以前の世代に戻すことができます：

```bash
# NixOS の場合
sudo nixos-rebuild switch --rollback

# Home Manager の場合
home-manager generations
home-manager switch --generation X  # X は世代番号
```

## ライセンス

このリポジトリは [MIT ライセンス](LICENSE) の下で公開されています。
