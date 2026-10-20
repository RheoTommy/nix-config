# Provides the shared rootless container runtime.
{ ... }:

{
  virtualisation.podman = {
    enable = true;
    # Provide Docker-compatible commands for tools that expect Docker.
    dockerCompat = true;
    # Allow containers on the default Podman network to resolve each other.
    defaultNetwork.settings.dns_enabled = true;
  };

  # Run arm64 binaries through QEMU, so containers for arm64 targets can be
  # built here. Static emulators also work inside containers.
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };
}
