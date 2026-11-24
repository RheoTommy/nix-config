# The Plasma 6 desktop behind the SDDM display manager, with the settings it
# needs for the shared input method and file indexing.
{ ... }:

{
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # KWin must launch Fcitx to pass it the Wayland input-method socket;
  # the package's generic autostart cannot establish that connection.
  environment.etc = {
    "xdg/kwinrc".text = ''
      [Wayland]
      InputMethod=/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop
    '';
    "xdg/autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Hidden=true
    '';
    # Baloo indexes the whole home by default, where source trees change far
    # too often for its index. An allowlist also keeps out directories that
    # do not exist yet, which an exclude list could not name in advance.
    "xdg/baloofilerc".text = ''
      [General]
      folders[$e]=$HOME/Desktop/,$HOME/Documents/,$HOME/Downloads/,$HOME/Music/,$HOME/Pictures/,$HOME/Videos/
      only basic indexing=true
    '';
  };
}
