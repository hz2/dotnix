{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.system.fonts;
in
{
  options.dotnix.system.fonts = {
    enable = lib.mkEnableOption "nerd fonts, noto and font-awesome";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [
        pkgs.nerd-fonts.hack
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.noto-fonts
        pkgs.noto-fonts-color-emoji
        pkgs.font-awesome
      ];
      defaultText = lib.literalExpression "nerd-fonts hack/fira-code/jetbrains-mono, noto, font-awesome";
      description = "Font packages to install system-wide.";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      fontconfig.enable = true;
      inherit (cfg) packages;
    };
  };
}
