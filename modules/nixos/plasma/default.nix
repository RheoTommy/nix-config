{ ... }:

{
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  services.desktopManager.plasma6.enable = true;

  # For fcitx diagnosis
  i18n.inputMethod.fcitx5.waylandFrontend = true;
}
