{ pkgs, ... }:

{
  home.packages = [
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.pavucontrol
    pkgs.wireplumber
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  programs.alacritty = {
    enable = true;
    settings.font.normal.family = "PlemolJP Console NF";
  };

  programs.fuzzel = {
    enable = true;
    settings.main = {
      font = "PlemolJP Console NF:size=11";
      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      show-failed-attempts = true;
    };
  };

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "niri.service" ];
    };
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      modules-left = [ "niri/workspaces" ];
      modules-center = [ "niri/window" ];
      modules-right = [
        "pulseaudio"
        "network"
        "clock"
        "tray"
      ];

      "niri/workspaces" = {
        format = "{index}";
      };
      "niri/window" = {
        max-length = 80;
      };
      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "muted";
        format-icons.default = [
          "low"
          "mid"
          "high"
        ];
        on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
      };
      network = {
        format-ethernet = "eth {ipaddr}";
        format-wifi = "wifi {essid}";
        format-disconnected = "offline";
        on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.networkmanager}/bin/nmtui";
      };
      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };
      tray.spacing = 8;
    };
  };

  services.mako.enable = true;

  services.swayidle = {
    enable = true;
    systemdTargets = [ "niri.service" ];
    timeouts = [
      {
        timeout = 600;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 660;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };

  systemd.user.services = {
    niri-background = {
      Unit = {
        Description = "Niri desktop background";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -c #1e1e2e";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    niri-mako = {
      Unit = {
        Description = "Notification daemon for Niri";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "niri.service" ];
    };

    niri-polkit-agent = {
      Unit = {
        Description = "Polkit authentication agent for Niri";
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service.ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Install.WantedBy = [ "niri.service" ];
    };
  };

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

        XF86AudioRaiseVolume = {
          _props.allow-when-locked = true;
          spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
        };
        XF86AudioLowerVolume = {
          _props.allow-when-locked = true;
          spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        };
        XF86AudioMute = {
          _props.allow-when-locked = true;
          spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        XF86AudioMicMute = {
          _props.allow-when-locked = true;
          spawn-sh = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };
        XF86AudioPlay = {
          _props.allow-when-locked = true;
          spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "play-pause"
          ];
        };
        XF86AudioPrev = {
          _props.allow-when-locked = true;
          spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "previous"
          ];
        };
        XF86AudioNext = {
          _props.allow-when-locked = true;
          spawn = [
            "${pkgs.playerctl}/bin/playerctl"
            "next"
          ];
        };
        XF86MonBrightnessUp = {
          _props.allow-when-locked = true;
          spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "--class=backlight"
            "set"
            "+10%"
          ];
        };
        XF86MonBrightnessDown = {
          _props.allow-when-locked = true;
          spawn = [
            "${pkgs.brightnessctl}/bin/brightnessctl"
            "--class=backlight"
            "set"
            "10%-"
          ];
        };
      };
    };
  };
}
