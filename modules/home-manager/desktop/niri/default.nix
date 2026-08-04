{ pkgs, ... }:

{
  wayland.windowManager.niri = {
    enable = true;

    # NixOS programs.niri owns the session units and portal integration.
    systemd.enable = false;
    portalPackage = null;

    # Keep the package non-null so Home Manager validates the generated KDL.
    package = pkgs.niri;
    xwaylandSatellitePackage = pkgs.xwayland-satellite;

    settings = {
      input = {
        keyboard.numlock = { };
        touchpad = {
          tap = { };
          natural-scroll = { };
        };
      };

      layout = {
        gaps = 12;
        center-focused-column = "never";
        preset-column-widths._children = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        default-column-width.proportion = 0.5;
      };

      prefer-no-csd = { };

      binds = {
        "Mod+Shift+Slash".show-hotkey-overlay = { };
        "Mod+T".spawn = [ "alacritty" ];
        "Mod+D".spawn = [ "fuzzel" ];
        "Super+Alt+L".spawn = [ "swaylock" ];

        "Mod+O" = {
          _props.repeat = false;
          toggle-overview = { };
        };
        "Mod+Q" = {
          _props.repeat = false;
          close-window = { };
        };

        "Mod+H".focus-column-left = { };
        "Mod+J".focus-window-down = { };
        "Mod+K".focus-window-up = { };
        "Mod+L".focus-column-right = { };
        "Mod+Ctrl+H".move-column-left = { };
        "Mod+Ctrl+J".move-window-down = { };
        "Mod+Ctrl+K".move-window-up = { };
        "Mod+Ctrl+L".move-column-right = { };

        "Mod+Shift+H".focus-monitor-left = { };
        "Mod+Shift+J".focus-monitor-down = { };
        "Mod+Shift+K".focus-monitor-up = { };
        "Mod+Shift+L".focus-monitor-right = { };
        "Mod+Ctrl+Shift+H".move-column-to-monitor-left = { };
        "Mod+Ctrl+Shift+J".move-column-to-monitor-down = { };
        "Mod+Ctrl+Shift+K".move-column-to-monitor-up = { };
        "Mod+Ctrl+Shift+L".move-column-to-monitor-right = { };

        "Mod+Page_Down".focus-workspace-down = { };
        "Mod+Page_Up".focus-workspace-up = { };
        "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };

        "Mod+BracketLeft".consume-or-expel-window-left = { };
        "Mod+BracketRight".consume-or-expel-window-right = { };
        "Mod+R".switch-preset-column-width = { };
        "Mod+F".maximize-column = { };
        "Mod+Shift+F".fullscreen-window = { };
        "Mod+V".toggle-window-floating = { };

        Print.screenshot = { };
        "Ctrl+Print".screenshot-screen = { };
        "Alt+Print".screenshot-window = { };

        "Mod+Escape" = {
          _props.allow-inhibiting = false;
          toggle-keyboard-shortcuts-inhibit = { };
        };
        "Mod+Shift+E".quit = { };
        "Mod+Shift+P".power-off-monitors = { };
      };
    };
  };
}
