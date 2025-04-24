{ lib, ... }:

{
    virtualisation.docker = lib.mkDefault {
        enable = true;
        rootless = {
            enable = true;
            setSocketVariable = true;
        };
    };
}