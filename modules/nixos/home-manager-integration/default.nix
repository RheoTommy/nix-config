{ inputs, ... }:

{
  # This imports Home Manager as a NixOS module, adding the `home-manager.*`
  # options used below. The user home configuration itself lives under `home/`.
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # When a file was created manually before being moved under Home Manager,
    # activation should preserve the old copy instead of failing on first switch.
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit inputs;
    };

    # Attach rheotommy's Home Manager configuration to the NixOS activation.
    users.rheotommy = import ../../../home/rheotommy;
  };
}
