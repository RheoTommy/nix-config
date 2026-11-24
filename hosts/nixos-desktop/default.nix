# Machine-specific configuration for the current desktop.
{ pkgs, ... }:

{
  imports = [
    # Shared policy is imported explicitly so each future host controls its scope.
    ../../modules/nixos/common
    ../../modules/nixos/home-manager-integration
    ../../modules/nixos/job-alerts
    ../../modules/nixos/op-secrets
    ../../modules/nixos/scheduled-jobs
    ../../modules/nixos/remote-access
    ../../modules/nixos/plasma
    ../../modules/nixos/secure-boot
    ./backup.nix
    ./disko.nix
    ./golink.nix
    ./hardware-configuration.nix
    ./home-assistant.nix
    ./jobs.nix
    ./memory-fault-workaround
    ./monitoring.nix
    ./secrets.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-desktop";

  boot.kernel.sysctl = {
    # By default the kernel kills the task that hit an oops and keeps running.
    # That can leave this host half alive and out of reach until someone
    # resets it by hand, so reboot instead. pstore keeps the oops log, which
    # the journal cannot record once the kernel has panicked.
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 10;
  };

  # Keep this host reachable over SSH; display blanking remains controlled by
  # the desktop environment independently of system sleep.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  # Only the account is declared here. Its home environment is managed by a
  # standalone Home Manager flake kept outside this repository.
  users.users.private = {
    isNormalUser = true;
    shell = pkgs.fish;
  };

  # Steam brings Proton, which runs Windows games and, through "Add a
  # Non-Steam Game", arbitrary Windows executables. It also enables the 32-bit
  # graphics stack those need.
  programs.steam.enable = true;

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
