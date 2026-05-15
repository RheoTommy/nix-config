{ ... }:

{
  imports = [
    ../../modules/nixos/common
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

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
      # RTX 3070 is Ampere, so the open NVIDIA kernel module is supported and preferred.
      open = true;
      # TODO: If suspend/resume is unstable on the desktop, test whether
      # hardware.nvidia.powerManagement.enable improves it before enabling.
    };
  };

  system.stateVersion = "25.11";
}
