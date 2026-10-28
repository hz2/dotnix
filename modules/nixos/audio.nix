{ config, lib, ... }:
let
  cfg = config.dotnix.system.audio;
in
{
  options.dotnix.system.audio.enable = lib.mkEnableOption "pipewire with alsa, pulse and wireplumber";

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
