{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.editors.neovim;
in
{
  options.dotnix.editors.neovim = {
    enable = lib.mkEnableOption "neovim with a lazy.nvim config symlinked from a checkout";
    package = lib.mkPackageOption pkgs "neovim" { };
    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/me/src/dotnix/config/nvim";
      description = ''
        Absolute path to a lua config checkout, linked out of the store so
        lazy.nvim can still write lazy-lock.json. Null leaves ~/.config/nvim alone.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."nvim" = lib.mkIf (cfg.configPath != null) {
      source = config.lib.file.mkOutOfStoreSymlink cfg.configPath;
    };
  };
}
