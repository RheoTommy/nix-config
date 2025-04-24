{ lib, ... }:

{
  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = lib.mkDefault false;
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = lib.mkDefault {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  programs = {
    noisetorch.enable = lib.mkDefault true;
  };
}
