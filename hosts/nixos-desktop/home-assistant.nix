# Runs Home Assistant, which controls the SwitchBot devices in the room over
# Bluetooth without their hub or cloud, and serves its web UI to the tailnet
# only.
{
  config,
  lib,
  options,
  ...
}:

let
  tailscale = lib.getExe config.services.tailscale.package;
  port = 8123;
in
{
  services.home-assistant = {
    enable = true;
    extraComponents = options.services.home-assistant.extraComponents.default ++ [ "switchbot" ];
    # No http section: Home Assistant ignores it after a one-time import,
    # which reverts unless confirmed in the web UI. The firewall keeps the
    # default port closed to the LAN.
    config.default_config = { };
  };

  systemd.services.tailscale-serve-home-assistant = {
    description = "Serve Home Assistant to the tailnet";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # TCP behind Tailscale's TLS rather than an HTTPS proxy: a proxy adds
    # X-Forwarded-For, which Home Assistant rejects unless the web UI is set up
    # for proxies. Not 8123, which Home Assistant holds on every address.
    script = ''
      ${tailscale} wait --timeout=2m
      ${tailscale} serve --bg --yes --tls-terminated-tcp=8124 tcp://127.0.0.1:${toString port}
    '';
  };
}
