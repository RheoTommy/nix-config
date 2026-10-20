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

  # Resolve short image names such as `node:22` on Docker Hub, as Docker does.
  # Dockerfiles and tools written for Docker rely on it.
  virtualisation.containers.registries.search = [ "docker.io" ];

  # Serve each user's rootless Podman through the Docker API socket, so tools
  # that talk to Docker directly, such as testcontainers, find it.
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];
  environment.sessionVariables.DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";

  # Run arm64 binaries through QEMU, so containers for arm64 targets can be
  # built here. Static emulators also work inside containers.
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };
}
