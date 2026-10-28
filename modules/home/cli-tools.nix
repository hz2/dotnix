{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.shell.cliTools;
in
{
  options.dotnix.shell.cliTools.enable = lib.mkEnableOption "bat, eza and lazygit";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.lazygit ];

    programs.bat = {
      enable = true;
      config = {
        theme = "base16";
        style = "changes,header";
      };
    };

    programs.eza = {
      enable = true;
      enableFishIntegration = true;
      git = true;
      icons = "auto";
    };
  };
}
