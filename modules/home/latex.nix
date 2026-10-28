{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.apps.latex;
in
{
  options.dotnix.apps.latex.enable = lib.mkEnableOption "texlive, ipe and typst";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.texlive.combined.scheme-full
      pkgs.ipe
      pkgs.poppler-utils
      pkgs.typst
    ];
  };
}
