# Shared hardware access, networking, timezone, and locale policy.
{ ... }:

{
  # Make redistributable device firmware available; generated host hardware
  # configuration also uses this flag to enable supported CPU microcode.
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;

  # NetworkManager supports both desktop UI management and command-line use.
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  # Keep program messages in English while using Japanese regional formats.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };
  };
}
