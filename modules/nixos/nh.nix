{ config, lib, ... }:
let
  cfg = config.dotnix.system.nh;
in
{
  options.dotnix.system.nh = {
    enable = lib.mkEnableOption "nh, a nicer nix cli with diffed generations";
    flake = lib.mkOption {
      type = lib.types.str;
      default = "${config.dotnix.user.homeDirectory}/dotnix";
      defaultText = lib.literalExpression ''"''${config.dotnix.user.homeDirectory}/dotnix"'';
      description = "Flake directory used as NH_FLAKE by nh os/home commands.";
    };
    clean = {
      enable = lib.mkEnableOption "periodic nh clean all via the nh-clean systemd timer";
      extraArgs = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "--keep-since 7d --keep 5";
        description = "Arguments passed to nh clean all on each timer run.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # programs.nh already warns if clean.enable and nix.gc.automatic are both
    # on; pick one gc path per host instead of asserting here.
    programs.nh = {
      enable = true;
      inherit (cfg) flake;
      clean = {
        inherit (cfg.clean) enable extraArgs;
      };
    };
  };
}
