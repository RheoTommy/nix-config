# Desktop services shared independently of the selected desktop environment.
{ pkgs, ... }:

{
  # Japanese IME settings.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
      # Enable the native Fcitx frontend used by Wayland compositors.
      waylandFrontend = true;
      settings = {
        globalOptions = {
          # Toggle between direct input and the active input method.
          "Hotkey/TriggerKeys"."0" = "Control+space";
        };
        # Define one group containing US direct input and Mozc, with Mozc as
        # the default input method for the group.
        inputMethod = {
          GroupOrder."0" = "Default";
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "mozc";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "mozc";
        };
      };
    };
  };

  # Prefer the native Qt Wayland input protocol, with Fcitx as a fallback.
  environment.sessionVariables.QT_IM_MODULES = "wayland;fcitx";

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    googlesans-code
    plemoljp
    plemoljp-nf
  ];

  services.printing.enable = true;

  # rtkit grants PipeWire audio threads controlled real-time scheduling.
  security.rtkit.enable = true;

  # Enable modern audio support with PipeWire.
  services.pipewire = {
    enable = true;
    # For compatibility.
    alsa.enable = true;
    pulse.enable = true;
  };

  # Install system integration for both the 1Password CLI and desktop app.
  # The GUI polkit owner is declared with the corresponding OS account.
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
}
