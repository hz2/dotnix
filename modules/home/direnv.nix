{ config, lib, ... }:
let
  cfg = config.dotnix.dev.direnv;
in
{
  options.dotnix.dev.direnv.enable = lib.mkEnableOption "direnv with nix-direnv";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
      silent = true;
    };
  };
}
