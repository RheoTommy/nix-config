# Provides the shared rootless container runtime.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.podman = {
    enable = true;
    # Provide Docker-compatible commands for tools that expect Docker.
    dockerCompat = true;
    # Allow containers on the default Podman network to resolve each other.
    defaultNetwork.settings.dns_enabled = true;
  };

  # `podman compose` and `docker compose` hand compose files to this provider.
  environment.systemPackages = [ pkgs.docker-compose ];

  # Resolve short image names such as `node:22` on Docker Hub, as Docker does.
  # Dockerfiles and tools written for Docker rely on it.
  virtualisation.containers.registries.settings.registries.search.registries = [
    "docker.io"
  ];

  # Serve each user's rootless Podman through the Docker API socket, so tools
  # that talk to Docker directly, such as testcontainers, find it.
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];
  environment.sessionVariables.DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";

  # Not virtualisation.podman.autoPrune: it runs as root and leaves each user's
  # rootless images alone.
  systemd.user.services.podman-prune = {
    description = "Prune Podman images older than three days";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe config.virtualisation.podman.package} image prune --all --force --filter until=72h";
      IOSchedulingClass = "idle";
    };
    startAt = "daily";
  };
  systemd.user.timers.podman-prune.timerConfig.Persistent = true;

  # Run arm64 binaries through QEMU, so containers for arm64 targets can be
  # built here. Static emulators also work inside containers.
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };
}
