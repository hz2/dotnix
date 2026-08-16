{ pkgs, ... }:

{
  home.packages = with pkgs; [
    texlive.combined.scheme-full
    ipe
    poppler-utils
  ];
}
