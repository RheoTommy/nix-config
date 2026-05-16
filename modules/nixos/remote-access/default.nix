{ ... }:

{
  # Remote access goes through the private tailnet. Run `sudo tailscale up` once
  # after activation to authenticate the host.
  services.tailscale.enable = true;
}
