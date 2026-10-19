# Boots through lanzaboote so the firmware can verify every boot image against
# this machine's own Secure Boot keys.
{
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  # lanzaboote installs a signed systemd-boot and signed kernel images in place
  # of the stock systemd-boot module, so that module stays disabled.
  boot.lanzaboote = {
    enable = true;
    # Created once with `sbctl create-keys`. The private keys stay outside the
    # Nix store, readable only by root.
    pkiBundle = "/var/lib/sbctl";
  };

  # Creates, enrolls and verifies the keys.
  environment.systemPackages = [ pkgs.sbctl ];
}
