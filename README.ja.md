# NixOS Home Manager 設定

このリポジトリには、NixOS用のモジュール式Home Manager設定が含まれており、他のオペレーティングシステムからもアクセスできます。シンプルでありながら拡張性があり、必要に応じて設定を追加または変更することが容易になっています。

## 構造

設定は以下のように整理されています：

```
.
├── flake.nix              # 設定のエントリーポイント
├── home
│   └── default.nix        # 基本的なhome-manager設定
├── hosts
│   └── nixos.nix          # NixOS固有の設定
└── modules
    ├── core               # すべての環境に必要な基本設定
    ├── desktop            # デスクトップ環境とGUIアプリケーション
    ├── development        # 開発環境とツール
    ├── editors            # テキストエディタとIDE
    └── shell              # シェルとターミナルユーティリティ
```

## はじめに

### 前提条件

- flakesが有効な[Nix](https://nixos.org/download.html)
- [Home Manager](https://github.com/nix-community/home-manager)

### インストール

1. このリポジトリをクローンします：

```bash
git clone https://github.com/yourusername/nix-config.git
cd nix-config
```

2. `flake.nix`の例示設定をあなたのユーザー名とホームディレクトリに合わせて変更します：

```
homeConfigurations = {
  "yourusername@hostname" = mkHomeConfiguration {
    system = "x86_64-linux"; # システムアーキテクチャを変更
    username = "yourusername";
    homeDirectory = "/home/yourusername";
    extraModules = [
      ./hosts/nixos.nix # または別のホスト設定
    ];
  };
};
```

3. 設定を適用します：

```bash
home-manager switch --flake .#yourusername@hostname
```

## 使用方法

### モジュールの有効化

モジュールを有効にするには、`home/default.nix`でそのインポートのコメントを解除します：

```
imports = [
  # コアモジュール
  ../modules/core

  # オプションモジュール
  ../modules/shell
  ../modules/editors
  # ../modules/desktop
  # ../modules/development
];
```

### モジュールのカスタマイズ

各モジュールディレクトリには、サブモジュールをインポートする`default.nix`ファイルが含まれています。サブモジュールを有効にするには、モジュールの`default.nix`ファイルでそのインポートのコメントを解除します。

例えば、editorsモジュールでNeovimの設定を有効にするには：

```
# In modules/editors/default.nix
imports = [
  # 必要に応じてコメントを解除
  # ./vim.nix
  ./neovim.nix
  # ./emacs.nix
  # ./vscode.nix
];
```

### 新しい設定の追加

新しい設定を追加するには：

1. 適切なモジュールディレクトリに新しい`.nix`ファイルを作成します
2. ファイルに設定を追加します
3. モジュールの`default.nix`ファイルでファイルをインポートします

## 他のオペレーティングシステムからの使用

この設定は、NixとHome Managerをインストールし、上記のインストール手順に従うことで、非NixOSシステムでも使用できます。flake.nixファイルには、LinuxやmacOSなど、複数のシステム用の設定が含まれています。

## 設定の拡張

モジュール式の構造により、設定の拡張が容易になっています：

1. `modules`ディレクトリに新しいモジュールを追加します
2. `hosts`ディレクトリにホスト固有の設定を作成します
3. 既存のモジュールを変更して設定を追加または変更します

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細はLICENSEファイルを参照してください。