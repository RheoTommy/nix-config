# NixOS Home Manager Configuration

This repository contains a modular Home Manager configuration for NixOS that can also be accessed from other operating systems. It is designed to be simple yet extensible, making it easy to add or modify configurations as needed.

## Structure

The configuration is organized as follows:

```
.
├── flake.nix              # Entry point for the configuration
├── home
│   └── default.nix        # Base home-manager configuration
├── hosts
│   └── nixos.nix          # NixOS-specific configurations
└── modules
    ├── core               # Essential configurations for all environments
    ├── desktop            # Desktop environments and GUI applications
    ├── development        # Development environments and tools
    ├── editors            # Text editors and IDEs
    └── shell              # Shells and terminal utilities
```

## Getting Started

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [Home Manager](https://github.com/nix-community/home-manager)

### Installation

1. Clone this repository:

```bash
git clone https://github.com/yourusername/nix-config.git
cd nix-config
```

2. Modify the example configuration in `flake.nix` to match your username and home directory:

```
homeConfigurations = {
  "yourusername@hostname" = mkHomeConfiguration {
    system = "x86_64-linux"; # Change to your system architecture
    username = "yourusername";
    homeDirectory = "/home/yourusername";
    extraModules = [
      ./hosts/nixos.nix # Or another host configuration
    ];
  };
};
```

3. Apply the configuration:

```bash
home-manager switch --flake .#yourusername@hostname
```

## Usage

### Enabling Modules

To enable a module, uncomment its import in `home/default.nix`:

```
imports = [
  # Core modules
  ../modules/core

  # Optional modules
  ../modules/shell
  ../modules/editors
  # ../modules/desktop
  # ../modules/development
];
```

### Customizing Modules

Each module directory contains a `default.nix` file that imports submodules. To enable a submodule, uncomment its import in the module's `default.nix` file.

For example, to enable the Neovim configuration in the `editors` module:

```
# In modules/editors/default.nix
imports = [
  # Uncomment as needed
  # ./vim.nix
  ./neovim.nix
  # ./emacs.nix
  # ./vscode.nix
];
```

### Adding New Configurations

To add a new configuration:

1. Create a new `.nix` file in the appropriate module directory
2. Add your configuration to the file
3. Import the file in the module's `default.nix` file

## Using from Other Operating Systems

This configuration can be used on non-NixOS systems by installing Nix and Home Manager, then following the installation instructions above. The flake.nix file includes configurations for multiple systems, including Linux and macOS.

## Extending the Configuration

The modular structure makes it easy to extend the configuration:

1. Add new modules in the `modules` directory
2. Create new host-specific configurations in the `hosts` directory
3. Modify existing modules to add or change configurations

## License

This project is licensed under the MIT License - see the LICENSE file for details.
