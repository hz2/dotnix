{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotnix.user;
in
{
  options.dotnix.user = {
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Login name of the primary user. Null disables user management.";
    };
    fullName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Display name, used for git identity when set.";
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Primary email, used for git identity.";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.name}";
      defaultText = lib.literalExpression ''"/home/''${config.dotnix.user.name}"'';
      description = "Home directory of the primary user.";
    };
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.fish;
      defaultText = lib.literalExpression "pkgs.fish";
      description = "Login shell of the primary user.";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Supplementary groups of the primary user.";
    };
  };

  config = lib.mkIf (cfg.name != null) {
    users.users.${cfg.name} = {
      isNormalUser = true;
      home = cfg.homeDirectory;
      inherit (cfg) shell extraGroups;
    };
  };
}
