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
    home.packages = with pkgs; [
      texlive.combined.scheme-full
      ipe
      poppler-utils
      typst
    ];
  };
}
