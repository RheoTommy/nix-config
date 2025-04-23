{ pkgs, lib, ... }:

{
    i18n = {
        defaultLocale = lib.mkDefault "ja_JP.UTF-8";
        extraLocaleSettings = lib.mkDefault {
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

        inputMethod = lib.mkDefault {
            enable = true;
            type = "fcitx5";
            # Enable Mozc-UT dictionary
            fcitx5.addons = [ pkgs.fcitx5-mozc-ut ];
        };
    };

    time = {
        timeZone = lib.mkDefault "Asia/Tokyo";
        hardwareClockInLocalTime = lib.mkDefault true;
    };
}
