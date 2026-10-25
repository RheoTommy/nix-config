# Files sent to this machine over Taildrop. tailscaled keeps them in its own
# inbox until something moves them out.
{ lib, pkgs, ... }:

{
  systemd.user.services.taildrop = {
    Unit.Description = "Move files received over Taildrop into ~/Downloads";
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Downloads";
      ExecStart = "${lib.getExe pkgs.tailscale} file get --wait --loop --conflict=rename %h/Downloads";
      Restart = "on-failure";
      # The default 100 ms runs into the start limit while tailscaled is down.
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
