# Records how this machine behaves, so that a problem can be traced afterwards.
# Gatus checks the Wi-Fi, the line and DNS once a minute, and below keeps the
# CPU, memory and I/O of every cgroup, which covers any unit without a monitor
# written for it. The Gatus status page is served to the tailnet only.
{ config, lib, ... }:

let
  tailscale = lib.getExe config.services.tailscale.package;
  port = 7318;
  network =
    endpoint:
    {
      group = "network";
      interval = "1m";
    }
    // endpoint;
  resolve =
    name: server:
    network {
      inherit name;
      url = server;
      dns = {
        query-name = "example.com";
        query-type = "A";
      };
      conditions = [ "[DNS_RCODE] == NOERROR" ];
    };
in
{
  # An overlay, because the below module has no package option. below in
  # nixpkgs from November 2026 lacks the zstd that its zstd-sys crate looks for
  # and fails to build. NixOS/nixpkgs#586021 adds it; once that reaches the
  # lock, this overlay leaves below as it is and warns.
  nixpkgs.overlays = [
    (final: prev: {
      below =
        if lib.any (input: lib.getName input == "zstd") prev.below.buildInputs then
          lib.warn "below in nixpkgs now has zstd: remove the overlay in hosts/nixos-desktop/monitoring.nix" prev.below
        else
          prev.below.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ [ final.zstd ];
          });
    })
  ];

  services.below = {
    enable = true;
    # Off by default, which would leave only whole-disk writes: not enough to
    # tell which unit is writing.
    collect.ioStats = true;
    compression.enable = true;
    retention = {
      time = 14 * 24 * 60 * 60;
      size = 30 * 1024 * 1024 * 1024;
    };
  };

  services.gatus = {
    enable = true;
    settings = {
      web = {
        address = "127.0.0.1";
        inherit port;
      };
      storage = {
        type = "sqlite";
        path = "/var/lib/gatus/data.db";
        # Keep each check for a year, so that a later look can compare times of
        # day, seasons, or before and after a change. Gatus's own charts and
        # averages reach back only 30 days.
        maximum-number-of-results = 365 * 24 * 60;
      };
      endpoints = [
        (network {
          name = "router";
          url = "icmp://192.168.3.1";
          conditions = [ "[CONNECTED] == true" ];
        })
        (network {
          name = "internet";
          url = "icmp://1.1.1.1";
          conditions = [ "[CONNECTED] == true" ];
        })
        # What applications use: MagicDNS in tailscaled, which forwards to the
        # tailnet's resolver.
        (resolve "dns" "100.100.100.100")
        # The tailnet's resolver (Control D) asked directly, to tell a slow
        # tailscaled apart from a slow resolver.
        (resolve "dns-upstream" "76.76.2.2")
      ];
    };
  };

  systemd.services.tailscale-serve-gatus = {
    description = "Serve Gatus to the tailnet";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Not 443: tailscale-serve-ovis serves Ovis there, and whichever of the two
    # runs last would replace the other.
    script = ''
      ${tailscale} wait --timeout=2m
      ${tailscale} serve --bg --yes --https=8443 http://127.0.0.1:${toString port}
    '';
  };
}
