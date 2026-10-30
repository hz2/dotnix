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
  # shared by the nixos and home-manager module trees
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
      description = "Supplementary groups of the primary user (nixos only).";
    };
    hashedPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file holding a crypted password hash (nixos only), usually
        a sops-nix secret with `neededForUsers = true`. Without this, a
        freshly declared or renamed user has no password at all: the account
        is locked, not blank, and no password will log it in, including
        after a rollback to an older generation that re-declares the same
        user (generations don't version /etc/shadow). Set one on every real
        host so console/rescue login always works.
      '';
    };
  };
}
