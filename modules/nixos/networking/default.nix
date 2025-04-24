{ lib, hostName, ... }:

{
  networking = {
    hostName = lib.mkDefault hostName;
    networkmanager.enable = lib.mkDefault true;
  };
}
