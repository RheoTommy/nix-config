# Restricts key-only SSH access to the private Tailscale interface, and serves
# Ovis, the web UI for herdr, to the tailnet over HTTPS.
{ config, lib, ... }:

let
  tailscale = lib.getExe config.services.tailscale.package;
in

{
  # Remote access goes through the private tailnet. Run `sudo tailscale up` once
  # after activation to authenticate the host.
  services.tailscale.enable = true;
  # Let rheotommy change Tailscale settings without sudo, such as the serve
  # setup that Ovis offers in its settings.
  services.tailscale.extraSetFlags = [ "--operator=rheotommy" ];

  # Publish Ovis, which listens on localhost only, at
  # https://<host>.<tailnet>.ts.net/ inside the tailnet. Serve is node state
  # kept by tailscaled; this sets it on every boot, so it matches this file.
  # Each run replaces the HTTPS 443 handler with the same one.
  systemd.services.tailscale-serve-ovis = {
    description = "Serve Ovis to the tailnet";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Serve needs a logged-in node. Give up after a while instead of holding
    # boot and activation while the node waits for `sudo tailscale up`.
    script = ''
      ${tailscale} wait --timeout=2m
      ${tailscale} serve --bg --yes --https=443 http://127.0.0.1:7317
    '';
  };

  services.openssh = {
    enable = true;
    # Do not open SSH on the public/LAN firewall. Port 22 is allowed only on the
    # Tailscale interface below.
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    22
  ];

  users.users.rheotommy.openssh.authorizedKeys.keys = [
    # Client key for logging in as `rheotommy` from the Ubuntu laptop.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4j3WYEaEKrXWFwm3ytPoZjV5ZfpctNQK13gc3uJWDG rheotommy@Ubuntu-Laptop"
    # Client key for logging in as `rheotommy` from the phone's SSH client.
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIyJu6mx9MWin1e4AGsqzBPv/lfgJSE2xfMMbmrBEabp ssh-term"
  ];

  # Start rheotommy's user services at boot and keep them after logout, so a
  # long-running session, such as one driven from a phone, survives reboots
  # and disconnects.
  users.users.rheotommy.linger = true;
}
