{ lib, ... }:

{
  home.file.".config/mozc/ibus_config.textproto" = {
    # This file is created by Mozc itself on first use. We intentionally take
    # ownership here so the IME mode engines and US layout stay declarative.
    force = true;
    text = ''
      engines {
        name : "mozc-on"
        longname : "Mozc:あ"
        layout : "us"
        layout_variant : ""
        layout_option : ""
        rank : 80
        symbol : "あ"
        composition_mode : HIRAGANA
      }
      engines {
        name : "mozc-off"
        longname : "Mozc:A"
        layout : "us"
        layout_variant : ""
        layout_option : ""
        rank : 80
        symbol : "A"
        composition_mode : DIRECT
      }
      active_on_launch: False
    '';
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/input-sources" = {
        # GNOME reads the active input methods from dconf; installing IBus/Mozc
        # alone does not add Mozc to the session's input-source list.
        sources = [
          (lib.hm.gvariant.mkTuple [
            "ibus"
            "mozc-off"
          ])
          (lib.hm.gvariant.mkTuple [
            "ibus"
            "mozc-on"
          ])
        ];
        mru-sources = [
          (lib.hm.gvariant.mkTuple [
            "ibus"
            "mozc-off"
          ])
          (lib.hm.gvariant.mkTuple [
            "ibus"
            "mozc-on"
          ])
        ];
        current = lib.hm.gvariant.mkUint32 0;
      };

      "org/freedesktop/ibus/general" = {
        preload-engines = [
          "mozc-on"
          "mozc-off"
        ];
        engines-order = [
          "mozc-on"
          "mozc-off"
        ];
        use-global-engine = true;
        # Keep the physical/layout mapping from the system XKB setting, which is
        # declared as US layout in the NixOS host configuration.
        use-system-keyboard-layout = true;
      };

      "org/freedesktop/ibus/general/hotkey" = {
        trigger = [ "Control+space" ];
        triggers = [ "<Control>space" ];
      };

      "org/gnome/desktop/wm/keybindings" = {
        switch-input-source = [ "<Control>space" ];
        switch-input-source-backward = [ "<Shift><Control>space" ];
      };

      "org/gnome/settings-daemon/plugins/power" = {
        # Desktop should only suspend when requested explicitly.
        "sleep-inactive-ac-type" = "nothing";
      };
    };
  };
}
