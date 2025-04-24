{ lib, ... }:

{
  services.displayManager = lib.mkDefault {
    sddm = {
      # TODO: Check!
      #            enable = true;
      wayland.enable = true;
    };
  };

  services.desktopManager.plasma6.enable = lib.mkDefault true;
}
