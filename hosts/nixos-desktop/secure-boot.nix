# Boots through lanzaboote so the firmware can verify every boot image against
# this machine's own Secure Boot keys.
{
  inputs,
  lib,
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

  # Booting a measured UKI makes systemd allocate its NvPCRs in the TPM. This
  # machine's Intel PTT fits only three of the four, and the login one, which
  # has the lowest priority, is skipped. Measure logins only when that NvPCR was
  # allocated, instead of failing on every login.
  # TODO: Drop this once nixpkgs has systemd 262, which sets the same condition;
  # the warning below says when. A default until then, so the update that
  # brings it does not conflict.
  systemd.services."systemd-pcrlogin@".unitConfig.ConditionPathExists =
    lib.warnIf (lib.versionAtLeast pkgs.systemd.version "262")
      "systemd is ${pkgs.systemd.version}: nixpkgs skips pcrlogin itself; drop the condition in secure-boot.nix"
      (lib.mkDefault "/run/systemd/nvpcr/login.anchor");
}
