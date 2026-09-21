# Machine-specific configuration for the current desktop.
{ ... }:

{
  imports = [
    # Shared policy is imported explicitly so each future host controls its scope.
    ../../modules/nixos/common
    ../../modules/nixos/home-manager-integration
    ../../modules/nixos/remote-access
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  networking.hostName = "nixos-desktop";

  # Windows on the other NVMe drive keeps the RTC in local time. Match it so
  # the clock does not shift by the timezone offset after each dual boot.
  time.hardwareClockInLocalTime = true;

  # This host has no swap partition. Compressed in-memory swap gives the kernel
  # room to reclaim idle pages without a disk-backed swap device. The default
  # size (50% of RAM) is enough for now.
  zramSwap.enable = true;

  # Keep this host reachable over SSH; display blanking remains controlled by
  # the desktop environment independently of system sleep.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  # Enable the NixOS desktop environment, including the Plasma 6 desktop and SDDM display manager.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # NVIDIA RTX 3070 graphics and suspend support.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    # RTX 3070 is supported by the open NVIDIA kernel module.
    open = true;
    # Preserve VRAM across suspend and resume.
    powerManagement.enable = true;
  };
  boot.kernelParams = [
    # Store preserved NVIDIA VRAM on disk instead of tmpfs during suspend.
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
  ];

  # Initial production baseline. Keep this value across future upgrades.
  system.stateVersion = "26.05";
}
