{ lib, ... }:

{
    # Enable OpenGL
    hardware.graphics.enable = lib.mkDefault true;
}