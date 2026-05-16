{ ... }:

{
  imports = [
    ../../modules/nixos/common
    ../../modules/nixos/home-manager-integration
    ../../modules/nixos/remote-access
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelParams = [
    # Store preserved NVIDIA VRAM on disk instead of tmpfs during suspend.
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];

  networking.hostName = "nixos-desktop";

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];

    xkb = {
      layout = "us";
      variant = "";
    };
  };
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  hardware = {
    graphics = {
      enable = true;
      # For Steam / Wine / Proton / 32-bit Vulkan/OpenGL support.
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      # RTX 3070 is Ampere, which is supported by NVIDIA's open kernel module.
      open = true;
      # Enables NVIDIA's systemd suspend/resume integration and preserves VRAM.
      powerManagement.enable = true;
    };
  };

  system.stateVersion = "25.11";
}
