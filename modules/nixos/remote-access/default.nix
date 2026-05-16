{ config, ... }:

{
  # Remote access goes through the private tailnet. Run `sudo tailscale up` once
  # after activation to authenticate the host.
  services.tailscale.enable = true;

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
  ];
}
