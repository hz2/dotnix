{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.ai.rtk;
in
{
  options.dotnix.ai.rtk = {
    enable = lib.mkEnableOption "rtk, which rewrites agent shell commands to trim token-heavy output";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.rtk or (pkgs.callPackage ../../../pkgs/rtk/package.nix { });
      defaultText = lib.literalExpression "pkgs.rtk";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    dotnix.ai.pi.extensions.rtk = lib.mkDefault ../../../config/pi/extensions/rtk.ts;
  };
}
