# Joins the host to the private tailnet. Run `sudo tailscale up` once after
# activation to authenticate the host.
{ ... }:

{
  services.tailscale.enable = true;
  # Lets rheotommy's services use tailscaled without sudo: Ovis changes serve,
  # and Taildrop receives files.
  services.tailscale.extraSetFlags = [ "--operator=rheotommy" ];
}
