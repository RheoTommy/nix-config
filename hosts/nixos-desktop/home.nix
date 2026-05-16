{ ... }:

{
  dconf = {
    enable = true;
    settings."org/gnome/settings-daemon/plugins/power" = {
      # Desktop should only suspend when requested explicitly.
      "sleep-inactive-ac-type" = "nothing";
    };
  };
}
