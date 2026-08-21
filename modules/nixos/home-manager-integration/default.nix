# Adds Home Manager support without binding the integration to a specific user.
{ inputs, ... }:

{
  # This imports Home Manager as a NixOS module, adding the `home-manager.*`
  # options used below. The user home configuration itself lives under `home/`.
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    # Reuse the NixOS pkgs instance, including its nixpkgs configuration.
    useGlobalPkgs = true;

    # Install home.packages under /etc/profiles/per-user instead of the separate
    # Home Manager profile under the home directory.
    useUserPackages = true;
  };
}
