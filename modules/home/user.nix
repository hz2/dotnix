{ config, lib, ... }:
let
  cfg = config.dotnix.user;
in
{
  imports = [ ../common/user.nix ];

  config = lib.mkIf (cfg.name != null) {
    home.username = lib.mkDefault cfg.name;
    home.homeDirectory = lib.mkDefault cfg.homeDirectory;
  };
}
